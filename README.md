# Obligatorio – Implementación de Soluciones Cloud

## Objetivo

Desplegar **Online Boutique** en AWS con Kubernetes K3s, balanceo de carga, tolerancia a fallas del plano de control, escalabilidad de frontend, almacenamiento persistente de Redis, respaldos y monitoreo. El proyecto se basa en la consigna **ISC-N5A – agosto 2026** y utiliza imágenes públicas oficiales de Online Boutique **v0.10.7**. La aplicación es de demostración: no procesa pagos reales.

> **Estado de entrega:** código preparado para prueba, **NO validado en una cuenta AWS Academy**. No se deben afirmar los 45 puntos ni la disponibilidad real antes de ejecutar y documentar las pruebas. La creación de roles IAM, NAT, EFS y AWS Backup puede estar limitada por permisos y cuotas del laboratorio.

## Arquitectura

- **VPC:** `10.80.0.0/16`, región `us-east-1`.
- **Tres AZ:** seleccionadas automáticamente entre las disponibles de la cuenta.
- **Seis subredes:** 3 públicas (`10.80.1.0/24` a `10.80.3.0/24`) y 3 privadas (`10.80.10.0/24`, `10.80.20.0/24`, `10.80.30.0/24`).
- **Internet Gateway y 3 NAT Gateway:** cada privada utiliza el NAT de su AZ. Los NAT consumen créditos mientras existan.
- **Tres EC2 `t3.medium`:** Amazon Linux 2023, 40 GiB gp3 cifrado, sin IP pública, administradas mediante SSM.
- **K3s:** tres servidores con etcd embebido, sin trabajadores dedicados. Dos miembros disponibles mantienen quórum si falla uno; esto no garantiza alta disponibilidad de todos los microservicios.
- **ALB público:** listener HTTP 80 y Target Group con NodePort 30080 en K3s. HTTP se usa solo con datos ficticios de laboratorio.
- **Redis:** un pod con AOF y volumen persistente NFS en EFS; recuperación mediante reprogramación del pod, con interrupción temporal. Los puntos de montaje EFS están en las tres AZ.
- **AWS Backup:** plan diario 03:00 UTC, retención 7 días y un vault.
- **CloudWatch:** tres alarmas de CPU EC2 y una de targets no saludables; SNS envía avisos por correo previa confirmación de suscripción.
- **HPA:** `frontend` de 2 a 4 réplicas con CPU objetivo del 60 %. Escala **pods**, no EC2. Requiere comprobar capacidad real.

El diagrama está en [`docs/arquitectura.drawio`](docs/arquitectura.drawio) y una imagen en [`docs/arquitectura.png`](docs/arquitectura.png).

## Requisitos

1. Windows PowerShell 5.1 o PowerShell 7.
2. AWS CLI v2 con credenciales vigentes y región `us-east-1` disponible.
3. Terraform >= 1.5, compatible con proveedor AWS 5.x y Random 3.x.
4. Cuenta AWS Academy **limpia** o con **el estado S3 previamente creado por este proyecto**; no reutilizar recursos ajenos al estado.
5. Cuota suficiente para tres EC2 `t3.medium`, tres NAT Gateway y Elastic IP, ALB, EFS, AWS Backup, SNS y roles IAM. Las restricciones de AWS Academy no se pueden verificar sin iniciar sesión.
6. Internet en la PC para descargar proveedores de Terraform y en las EC2 privadas mediante los NAT para descargar K3s e imágenes.

## Configuración (único archivo editable)

Antes de desplegar, abrir `config.psd1` y sustituir **ambos** ejemplos:

```powershell
@{
    alerta_mail   = "correo@ejemplo.com"
    nombre_bucket = "nombre-unico-del-bucket"
}
```

- `alerta_mail`: correo real al que llegarán notificaciones SNS.
- `nombre_bucket`: nombre S3 globalmente único, con letras minúsculas, números y guiones (p. ej. `isc-estado-equipo-2026-12345`). Si ya está usado por otra cuenta, elegir otro nombre.
- No colocar credenciales en el archivo, no modificar nombres de recursos para efectuar un despliegue sobre un estado ya creado.
- Este archivo **se incluye en GitHub solamente con los valores de ejemplo**. No subir correos personales ni datos privados por error.

## Validar y desplegar

Desde PowerShell, en el directorio raíz del proyecto:

```powershell
.\validar.ps1
```

Este comando consulta AWS y ejecuta `terraform fmt`, `init -backend=false` y `validate`, sin crear recursos AWS. **Esto no demuestra** que los permisos AWS permitan crear toda la infraestructura.

Si la validación finaliza correctamente y la cuenta está destinada al obligatorio:

```powershell
.\desplegar.ps1
```

El script debe crear/reutilizar el bucket remoto S3, activar cifrado AES256, versionado y bloqueo público, inicializar Terraform, evaluar el plan, aplicar cambios permitidos, configurar K3s y desplegar los manifiestos. **Bloquea cualquier plan que contenga una acción `delete`, incluso sustituciones.** No puede detectar recursos extranjeros automáticamente en todos los casos: ante un conflicto o error, no borrar ni importar recursos sin revisar el estado.

La salida correcta de cada fase es su título seguido de `OK`. Si algo falla muestra `ERROR` y la causa. Cuando termina imprime:

```text
Podes acceder a ONLINE BOUTIQUE desde: http://DNS-DEL-ALB
```

El primer despliegue puede tardar debido a las EC2, K3s, imágenes y health checks. El script no debe considerarse exitoso si algún microservicio o una comprobación esencial falla. **Confirmar la suscripción SNS en el correo que llegue de AWS**: es el único paso manual posterior obligatorio para recibir las alertas.

## Seguridad

- Solo el ALB recibe tráfico desde Internet en TCP/80.
- EC2 privadas sin IP pública, puerto 22 cerrado; conectar desde EC2 > Connect > Session Manager.
- ALB llega a K3s por TCP/30080. EFS recibe NFS/TCP/2049 solo desde el Security Group K3s. Los nodos se comunican entre sí dentro de su SG.
- Para producción se requerirían HTTPS, segmentación de permisos Kubernetes, mecanismos adicionales de alta disponibilidad de Redis y controles de seguridad más avanzados.
- Los tokens del clúster K3s están protegidos en el estado Terraform cifrado S3; restringir acceso al bucket.

## Comprobaciones para la defensa

Registrar evidencia de:

1. `terraform validate` sin errores y plan inicial solo `create`.
2. VPC, 6 subredes y rutas privadas a 3 NAT.
3. 3 EC2 `running`, `SSM Online`, `kubectl get nodes` con 3 nodos `Ready`.
4. `kubectl get deployments,pods,svc,hpa,pvc,pv` sin microservicios indisponibles, y HPA configurado.
5. ALB con al menos 2 targets saludables y navegación de catálogo/carrito/checkout de prueba.
6. EFS con mount targets, `redis-cli CONFIG GET appendonly` activo; comprobar persistencia tras reinicio controlado de pod.
7. Plan AWS Backup con cron diario y `delete_after=7`. **Verificar que exista al menos un punto de recuperación** antes de afirmar que los datos ya están respaldados; el primer backup no se completa instantáneamente.
8. CPU y targets alarmados en CloudWatch; recepción SNS solo después de confirmar el correo.
9. Escalado HPA con una carga **controlada**, monitorizando CPU y capacidad de las instancias. Con tres EC2 fijas no se puede prometer capacidad ilimitada.
10. Simulación de caída de un nodo con cuidado, verificando etcd, distribución de pods y recuperación de Redis; puede producir interrupciones temporales.

## Recuperación y costos

AWS Backup permite restaurar EFS a un sistema de archivos separado, pero **este proyecto no implementa restauración automática**. La demostración de restauración debe documentarse antes de la defensa. No lanzar pruebas destructivas con datos que quieras conservar.

Los **tres NAT Gateway, tres EC2 y el ALB** generan costos/créditos; apagarlos individualmente puede romper el laboratorio. Para eliminar toda la infraestructura de prueba hay que revisar el estado y ejecutar un procedimiento destructivo **separado y aprobado explícitamente**; `desplegar.ps1` nunca destruye recursos.

## Archivos

- `config.psd1`: correo y bucket.
- `validar.ps1`: requisitos y validación estática.
- `desplegar.ps1`: flujo de despliegue y comprobaciones por SSM.
- `terraform/`: `main.tf`, `variables.tf`, `outputs.tf`, `providers.tf`, y cinco módulos.
- `kubernetes/app.yaml`: once deployments (10 servicios + Redis), servicios, HPA, PV y PVC.
- `docs/arquitectura.drawio`: editable en diagrams.net; `docs/arquitectura.png`: vista previa.
- `aplicacion-original.zip`: copia del material suministrado para trazabilidad; el despliegue **no compila** su código.

## Trabajo colaborativo y entrega

Crear branches de trabajo reales, commits descriptivos y pull requests revisados por los integrantes. No inventar historial. La consigna pide documentar el uso de IA y verificar la autoría y la comprensión técnica. En Gestión ORT se entrega un ZIP/RAR (máximo 40 MB) y un PDF con la URL del repositorio Git, con el contenido exigido por la consigna. Preparar la defensa presencial o remota según lo comunique el docente.

## Uso de IA

Se utilizó ChatGPT de OpenAI para apoyar el diseño de arquitectura, redactar Terraform, PowerShell, manifiestos y documentación, y revisar la consistencia. El equipo es responsable de validar en AWS, documentar las pruebas, comprender el código y corregir posibles problemas antes de la entrega. No afirmar que los resultados han sido comprobados en AWS hasta ejecutarlos efectivamente.

## Fuentes

- Consigna ORT «ISC-N5A Obligatorio – Agosto 2026», material suministrado por el equipo.
- Aplicación Online Boutique suministrada en `Obligatorio-Microservicios-build-modernize-runtimes-eks.zip` (incluida como `aplicacion-original.zip`).
- GoogleCloudPlatform/microservices-demo, manifiestos oficiales de la versión v0.10.7: <https://github.com/GoogleCloudPlatform/microservices-demo/blob/main/release/kubernetes-manifests.yaml>.
- Documentación AWS: EC2, SSM, ALB, EFS, AWS Backup, IAM y CloudWatch.
