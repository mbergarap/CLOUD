# Obligatorio – Implementación de Soluciones Cloud

## Objetivo

Desplegar **Online Boutique** en AWS mediante Kubernetes K3s, balanceo de carga, tolerancia a fallas del plano de control, escalabilidad del frontend, almacenamiento persistente de Redis, respaldos y monitoreo.

El proyecto se basa en la consigna **ISC-N5A – agosto 2026** y utiliza imágenes públicas oficiales de **Online Boutique v0.10.7**. La aplicación es demostrativa y no procesa pagos reales.

**Estado:** se completó satisfactoriamente un despliegue automatizado desde una cuenta AWS Academy reiniciada el 23/11/2026, con tres nodos K3s Ready, microservicios disponibles y respuesta HTTP 200 del balanceador. Las mejoras posteriores, especialmente el respaldo de etcd a S3, requieren una nueva validación.

## Arquitectura

- **Región:** `us-east-1`.
- **VPC:** `10.80.0.0/16`.
- **Zonas de disponibilidad:** tres AZ seleccionadas automáticamente por Terraform.
- **Subredes públicas:** `10.80.1.0/24`, `10.80.2.0/24` y `10.80.3.0/24`.
- **Subredes privadas:** `10.80.10.0/24`, `10.80.20.0/24` y `10.80.30.0/24`.
- **Internet Gateway:** proporciona salida y entrada de Internet mediante las rutas públicas.
- **NAT Gateways:** tres, uno por AZ, para la salida a Internet de las subredes privadas.
- **EC2:** tres instancias privadas `t3.medium`, sin dirección IP pública.
- **K3s:** tres servidores con etcd embebido y quórum distribuido.
- **Application Load Balancer:** público, listener HTTP 80 y Target Group en TCP 30080.
- **Online Boutique:** microservicios desplegados mediante manifiestos Kubernetes.
- **Redis:** ejecutado como pod Kubernetes, con persistencia AOF mediante Amazon EFS.
- **Amazon EFS:** tres puntos de montaje, uno por AZ.
- **AWS Backup:** plan de respaldo diario para EFS.
- **Amazon S3:** backend remoto de Terraform y bucket independiente para snapshots de etcd.
- **CloudWatch y SNS:** alarmas de infraestructura y notificaciones por correo.
- **HPA:** escalado del frontend de 2 a 4 réplicas, con CPU objetivo del 60 %.

El plano de control tolera la pérdida de un miembro de etcd mientras permanezcan dos miembros disponibles. Esto no garantiza que todos los microservicios permanezcan disponibles durante cualquier falla.

El diagrama editable se encuentra en [`docs/arquitectura.drawio`](docs/arquitectura.drawio), con su representación PNG en [`docs/arquitectura.png`](docs/arquitectura.png).

## Infraestructura y versiones

| Componente                 | Tipo o versión            | Configuración                                     |
| -------------------------- | ------------------------- | ------------------------------------------------- |
| Región AWS                 | `us-east-1`               | Norte de Virginia                                 |
| Servidores EC2             | `t3.medium`               | 3 instancias, 2 vCPU y 4 GiB RAM cada una         |
| Sistema operativo          | Amazon Linux 2023         | Última AMI coincidente al desplegar               |
| Disco EC2                  | EBS `gp3`                 | 40 GiB cifrados por instancia                     |
| Kubernetes                 | K3s                       | Tres servidores con etcd embebido                 |
| K3s probado                | `v1.37.2+k3s1`            | Versión observada en el despliegue del 23/11/2026 |
| Aplicación                 | Online Boutique `v0.10.7` | Imágenes públicas                                 |
| Terraform                  | `>= 1.5`                  | Infraestructura como código                       |
| Proveedor Terraform AWS    | Serie `5.x`               | Versión exacta fijada en `.terraform.lock.hcl`    |
| Proveedor Terraform Random | Serie `3.x`               | Generación del token K3s                          |
| Balanceador                | Application Load Balancer | HTTP 80 → NodePort 30080                          |
| Almacenamiento             | Amazon EFS                | Redis persistente mediante NFS                    |
| Sistema de monitoreo       | Amazon CloudWatch         | Alarmas de EC2 y ALB                              |

La versión exacta de K3s no está fijada en las plantillas de instalación: el instalador descarga la versión disponible al ejecutarse. Para garantizar reproducibilidad estricta se debería fijar explícitamente una versión y probarla.

## Requisitos

1. Windows PowerShell 5.1 o PowerShell 7.
2. AWS CLI v2 instalado y configurado con credenciales vigentes.
3. Terraform compatible con los proveedores del proyecto.
4. Cuenta AWS Academy limpia, o infraestructura previa administrada por el estado remoto del mismo proyecto.
5. Cuotas y permisos suficientes para EC2, NAT Gateway, ALB, EFS, S3, AWS Backup, CloudWatch y SNS.
6. Conectividad a Internet para descargar Terraform, K3s y las imágenes de los contenedores.

## Configuración

El archivo privado `config.psd1` debe crearse a partir de `config.example.psd1`.

Ejemplo:

```powershell
@{
    alerta_mail   = "correo@ejemplo.com"
    nombre_bucket = "nombre-unico-del-bucket"
}
```

- `alerta_mail`: dirección que recibirá las notificaciones SNS.
- `nombre_bucket`: nombre globalmente único del bucket S3 para el backend Terraform.

**No publicar `config.psd1` ni credenciales AWS.** El repositorio versiona únicamente `config.example.psd1` con valores ficticios.

## Validación y despliegue

Desde PowerShell, en la raíz del proyecto:

```powershell
.\validar.ps1
```

Este comando comprueba requisitos y configuración, pero no garantiza que AWS permita crear todos los recursos.

Para desplegar:

```powershell
.\desplegar.ps1
```

El script automatiza:

1. Validación de configuración y credenciales.
2. Creación o configuración del backend remoto S3.
3. Inicialización, validación, planificación y aplicación de Terraform.
4. Instalación y verificación del clúster K3s.
5. Despliegue de Online Boutique.
6. Validación de Redis y EFS.
7. Verificación de monitoreo y configuración de AWS Backup.
8. Comprobación del balanceador y respuesta HTTP 200.

El script bloquea planes Terraform que incluyan eliminaciones o reemplazos. No debe utilizarse para destruir recursos.

Al finalizar correctamente, muestra la dirección pública de Online Boutique.

La suscripción SNS requiere confirmar el correo enviado por AWS para empezar a recibir notificaciones.

## Seguridad de red — Security Groups

La infraestructura utiliza tres Security Groups principales: ALB, K3s y EFS.

| Origen               | Destino              | Protocolo / puerto | Motivo                              |
| -------------------- | -------------------- | ------------------ | ----------------------------------- |
| Internet `0.0.0.0/0` | ALB                  | TCP 80             | Acceso público a Online Boutique    |
| ALB                  | K3s                  | TCP 30080          | Tráfico del balanceador al NodePort |
| K3s                  | K3s                  | TCP 6443           | API de Kubernetes                   |
| K3s                  | K3s                  | TCP 2379–2380      | Comunicación etcd                   |
| K3s                  | K3s                  | TCP 10250          | API de Kubelet                      |
| K3s                  | K3s                  | UDP 8472           | Red Flannel VXLAN                   |
| K3s                  | EFS                  | TCP 2049           | Persistencia mediante NFS           |
| K3s                  | Internet `0.0.0.0/0` | TCP 443            | HTTPS y servicios AWS               |
| K3s                  | Internet `0.0.0.0/0` | TCP 80             | Instalación y descargas HTTP        |
| K3s                  | VPC `10.80.0.0/16`   | TCP/UDP 53         | Consultas DNS                       |
| ALB                  | VPC `10.80.0.0/16`   | TCP 30080          | Salida hacia Kubernetes             |

### Medidas de seguridad

- Las EC2 se encuentran únicamente en subredes privadas.
- Ninguna EC2 recibe una IP pública.
- No se habilita SSH TCP 22 desde Internet.
- La administración utiliza AWS Systems Manager mediante `LabInstanceProfile`.
- El ALB solo expone HTTP 80.
- El Security Group de EFS permite NFS desde K3s.
- Los puertos internos de Kubernetes utilizan referencias al propio Security Group del clúster.
- Los volúmenes EBS y el sistema de archivos EFS están cifrados.
- El backend S3 utiliza cifrado, versionado y bloqueo de acceso público.

Las reglas de salida se limitan a los protocolos necesarios declarados en Terraform.

**Observación:** el Security Group de K3s utiliza `ignore_changes` en `ingress` y `egress`. Se deben comprobar las reglas efectivas de AWS durante la validación final. También deben revisarse los permisos de salida efectivos del Security Group de EFS.

Para un entorno productivo serían necesarios HTTPS, controles IAM más específicos y endurecimiento adicional.

## Respaldos y recuperación

### Redis y EFS

AWS Backup dispone de:

- Un Backup Vault.
- Un plan de respaldos diarios a las 03:00 UTC.
- Retención de 7 días.
- Asociación del sistema de archivos EFS al plan.

La creación del plan se realiza mediante Terraform.

**Pendiente de validación:** comprobar que se complete al menos un trabajo de backup y exista un punto de recuperación utilizable.

### Kubernetes y etcd

K3s utiliza etcd embebido para mantener el estado del clúster.

Se incorporó una configuración de snapshots con:

- Frecuencia de 12 horas.
- Almacenamiento externo en un bucket Amazon S3 privado.
- Cifrado del bucket y bloqueo de acceso público.
- Eliminación de objetos después de 7 días mediante una política de ciclo de vida.

**Pendiente de validación en AWS Academy:** comprobar los permisos de S3 del perfil `LabInstanceProfile`, verificar la creación de snapshots y ejecutar una prueba de recuperación.

La infraestructura no implementa restauración automática de EFS ni del clúster Kubernetes.

## Monitoreo

El módulo CloudWatch incluye alarmas de CPU para las tres instancias EC2 y una alarma relacionada con los destinos no saludables del ALB.

Amazon SNS envía las notificaciones a la dirección configurada, una vez confirmada la suscripción por correo.

## Comprobaciones para la defensa

1. Terraform valida sin errores.
2. La VPC contiene seis subredes distribuidas en tres AZ.
3. Las subredes privadas utilizan sus respectivos NAT Gateways.
4. Las tres EC2 están `running` y disponibles en SSM.
5. Los tres nodos Kubernetes están `Ready`.
6. Los microservicios de Online Boutique están disponibles.
7. Redis responde `PONG` y tiene AOF habilitado.
8. EFS proporciona almacenamiento persistente al pod Redis.
9. El ALB tiene destinos saludables y responde HTTP 200.
10. El HPA del frontend está configurado.
11. Existen las alarmas CloudWatch y la suscripción SNS.
12. AWS Backup tiene un plan y una selección de recursos configurados.
13. Se verifica al menos un respaldo recuperable de EFS.
14. Se comprueba que los snapshots de etcd lleguen a S3.
15. Se documentan las pruebas de recuperación y cualquier limitación del laboratorio.

Los puntos 13 a 15 aún requieren evidencia de ejecución.

## Costos y eliminación de recursos

Los tres NAT Gateways, las tres instancias EC2, el ALB, EFS y el resto de servicios pueden consumir créditos AWS Academy mientras estén desplegados.

El laboratorio debe utilizarse considerando su presupuesto y las restricciones de permisos.

La eliminación de infraestructura debe realizarse mediante un procedimiento separado, revisado y autorizado. `desplegar.ps1` no ejecuta destrucciones automáticas.

## Estructura del proyecto

| Archivo o carpeta               | Función                                      |
| ------------------------------- | -------------------------------------------- |
| `README.md`                     | Documentación del obligatorio                |
| `config.example.psd1`           | Ejemplo de configuración                     |
| `config.psd1`                   | Configuración local privada, excluida de Git |
| `desplegar.ps1`                 | Despliegue automatizado                      |
| `validar.ps1`                   | Validaciones previas                         |
| `terraform/`                    | Infraestructura Terraform                    |
| `terraform/modules/network/`    | VPC, subredes, Internet Gateway y NAT        |
| `terraform/modules/security/`   | Security Groups                              |
| `terraform/modules/compute/`    | EC2, K3s y ALB                               |
| `terraform/modules/storage/`    | EFS, AWS Backup y S3 de etcd                 |
| `terraform/modules/monitoring/` | CloudWatch y SNS                             |
| `kubernetes/app.yaml`           | Manifiestos de Online Boutique               |
| `docs/arquitectura.drawio`      | Diagrama editable                            |
| `docs/arquitectura.png`         | Diagrama exportado                           |

## Trabajo colaborativo y entrega

El repositorio Git conserva el código y la documentación del proyecto.

Las modificaciones deben registrarse mediante commits descriptivos. La entrega académica debe ajustarse a los archivos, formatos y requisitos establecidos en la consigna de ORT.

La validación de la infraestructura, la comprensión de los componentes y la defensa del trabajo son responsabilidad del equipo.

## Uso de inteligencia artificial

Se utilizó **ChatGPT de OpenAI** como herramienta de apoyo en el diseño de la arquitectura, la elaboración y revisión de Terraform, los scripts PowerShell, los manifiestos Kubernetes y la documentación técnica.

Los resultados generados o revisados con asistencia de IA fueron evaluados por el equipo. La responsabilidad por el funcionamiento, las pruebas, las decisiones de arquitectura y la entrega corresponde a sus integrantes.

## Fuentes

- Consigna ORT: *ISC-N5A – Obligatorio, agosto 2026*.
- Proyecto Google Online Boutique: [https://github.com/GoogleCloudPlatform/microservices-demo](https://github.com/GoogleCloudPlatform/microservices-demo)
- Documentación de K3s: [https://docs.k3s.io/](https://docs.k3s.io/)
- Documentación de Terraform: [https://developer.hashicorp.com/terraform/docs](https://developer.hashicorp.com/terraform/docs)
  - Documentación oficial de AWS: [https://docs.aws.amazon.com/](https://docs.aws.amazon.com/)
