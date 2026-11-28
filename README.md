# Obligatorio – Implementación de Soluciones Cloud (ISC-N5A)

Despliegue automatizado de **Online Boutique** (e-commerce de microservicios) en AWS con **Terraform** y **K3s**, pensado para soportar picos de tráfico y la caída de una zona de disponibilidad.

**Estado:** la variante de cuatro comandos se desplegó exitosamente en AWS Academy y Online Boutique respondió HTTP 200 con tres targets saludables. Esto no acredita por sí solo todas las pruebas funcionales de respaldo, recuperación y observabilidad.

![Arquitectura](docs/arquitectura.png)

> Diagrama editable (draw.io, con iconografía AWS): [`docs/arquitectura.drawio`](docs/arquitectura.drawio).

## Correspondencia con la consigna

| Componente original | Equivalente en AWS |
|---|---|
| Load balancer | Application Load Balancer (HTTP 80 → NodePort 30080) |
| Dos servidores de aplicación | 3 EC2 `t3.medium` con K3s (etcd embebido), una por AZ; pods replicados |
| Base de datos | Redis (almacén de carritos de Online Boutique) con persistencia AOF sobre Amazon EFS cifrado |
| Solución de respaldos | AWS Backup (EFS, diario) + snapshots de etcd cada 12 h (copia a S3 con reintento, ver [`docs/RESPALDOS.md`](docs/RESPALDOS.md)) |

Detalle y justificación en [`docs/ARQUITECTURA.md`](docs/ARQUITECTURA.md).

## Documentación

| Documento | Contenido |
|---|---|
| [`docs/ARQUITECTURA.md`](docs/ARQUITECTURA.md) | Servicios AWS, red, cómputo, tolerancia a fallas y escalabilidad |
| [`docs/SEGURIDAD.md`](docs/SEGURIDAD.md) | Security Groups regla por regla y medidas de seguridad |
| [`docs/RESPALDOS.md`](docs/RESPALDOS.md) | Respaldos y procedimientos de recuperación |
| [`docs/MONITOREO.md`](docs/MONITOREO.md) | Alarmas, dashboard y logs centralizados |
| [`docs/OPERACION.md`](docs/OPERACION.md) | Despliegue, configuración, variables y operación |
| [`docs/COMPATIBILIDAD-AWS-ACADEMY.md`](docs/COMPATIBILIDAD-AWS-ACADEMY.md) | Restricciones de AWS Academy y decisiones tomadas por ellas |
| [`docs/PRUEBAS.md`](docs/PRUEBAS.md) | Pruebas de carga y de fallas (procedimiento y registro de resultados) |

## Inicio rápido

Para una **cuenta AWS Academy limpia**, con Terraform instalado y credenciales de AWS configuradas (AWS CLI v2):

```powershell
cd terraform
terraform init
terraform validate
terraform plan
terraform apply
```

Antes de iniciar, copiar `terraform/terraform.tfvars.example` a `terraform/terraform.tfvars` y completar `alerta_mail` y `nombre_bucket`. El nombre del bucket debe ser **único en todo S3** (se sugiere terminarlo con el ID de 12 dígitos de la cuenta). No hace falta crear buckets ni configurar SSH: no hay acceso SSH público a los nodos y se administra por SSM. Confirmar el plan antes de responder `yes` a `apply`.

En `apply`, Terraform crea VPC, seguridad, EC2, EFS, ALB, logs, AWS Backup, SNS y CloudWatch. Las EC2 se configuran solas con `user_data`: instalan K3s, etiquetan su zona de disponibilidad, el nodo principal crea el bucket de snapshots de etcd con el rol de la instancia y aplica Online Boutique. Al final, una asociación de SSM (`aws_ssm_association.verificar_kubernetes`) espera 3 nodos `Ready`, las 2 réplicas del frontend y un HTTP 200 por el ALB. **No hay scripts que ejecutar a mano.**

**Estado local:** el archivo `terraform/terraform.tfstate` contiene secretos como el token de K3s. La carpeta del proyecto debe permanecer privada; no subir el archivo ni las copias `.backup` a Git, no borrarlo y no intercambiarlo entre cuentas. Para trabajo en equipo simultáneo resulta más seguro un estado remoto con bloqueo, pero la consigna no exige esa modalidad.

**ADVERTENCIA:** no ejecutar contra una cuenta que ya tiene el obligatorio creado con otro estado: Terraform podría intentar crear recursos duplicados. Esta ruta se probó con `apply` real, HTTP 200 y tres targets sanos; las demás verificaciones están documentadas en [`docs/PRUEBAS.md`](docs/PRUEBAS.md).

**Si falla la verificación final:** no borrar el estado ni ejecutar `destroy`. Entrar a un nodo con `aws ssm start-session --target <id>`, revisar `/var/log/isc-k3s-install.log` y volver a ejecutar `terraform apply` una vez resuelta la causa.

Más detalle en [`docs/OPERACION.md`](docs/OPERACION.md).

## Requisitos y versiones

| Componente | Versión |
|---|---|
| Windows PowerShell (solo para los scripts de `pruebas/`) | 5.1 o PowerShell 7 |
| AWS CLI | v2 |
| Terraform | `>= 1.5.0` (CI con 1.9.x) |
| Proveedor `hashicorp/aws` | `~> 5.0` (versión exacta en `terraform/.terraform.lock.hcl`) |
| Proveedor `hashicorp/random` | `~> 3.6` |
| K3s | `v1.37.2+k3s1` (variable `version_k3s`) |
| Online Boutique | `v0.10.7` |
| k6 (solo pruebas de carga) | cualquiera reciente |

## Estructura del repositorio

| Ruta | Función |
|---|---|
| `terraform/` | Raíz de Terraform (`main.tf`, `variables.tf`, `outputs.tf`, `providers.tf`) |
| `terraform/modules/network/` | VPC, subredes, Internet Gateway, NAT |
| `terraform/modules/security/` | Security Groups y reglas |
| `terraform/modules/compute/` | EC2 K3s (user_data), ALB y Target Group |
| `terraform/modules/storage/` | EFS y AWS Backup |
| `terraform/modules/logging/` | Grupo de CloudWatch Logs de nodos y pods |
| `terraform/modules/monitoring/` | Alarmas, dashboard y SNS |
| `kubernetes/app.yaml` | Manifiestos de Online Boutique, HPA y PDB |
| `pruebas/` | Scripts de carga (k6) y de falla de instancia |
| `docs/` | Documentación y diagrama |
| `.github/workflows/terraform.yml` | CI: `fmt` y `validate` (bloquean) más TFLint y Checkov (informativos) |
| `terraform/automatizacion.tf` | Verificación final por SSM (3 nodos Ready, frontend y HTTP 200 por el ALB) |

## Uso de inteligencia artificial

Se utilizó **ChatGPT de OpenAI** como herramienta de apoyo en el diseño de la arquitectura, la elaboración y revisión de Terraform, los scripts PowerShell, los manifiestos Kubernetes y la documentación técnica.

Los resultados generados o revisados con asistencia de IA fueron evaluados por el equipo. La responsabilidad por el funcionamiento, las pruebas, las decisiones de arquitectura y la entrega corresponde a sus integrantes.

## Fuentes

- Consigna ORT: *ISC-N5A – Obligatorio, agosto 2026*.
- Proyecto Google Online Boutique: <https://github.com/GoogleCloudPlatform/microservices-demo>
- Documentación de K3s: <https://docs.k3s.io/>
- Documentación de Terraform: <https://developer.hashicorp.com/terraform/docs>
- Documentación oficial de AWS: <https://docs.aws.amazon.com/>


## Nota de portabilidad y AWS Academy

Terraform conserva estado local. El bucket de snapshots de etcd **no** lo crea el proveedor AWS: lo crea el `user_data` del nodo principal con AWS CLI y el rol de la instancia. Así se evita la consulta de Object Lock que la SCP de AWS Academy deniega, y `apply` no depende de PowerShell. La ruta `terraform apply` se probó en AWS Academy; las pruebas de carga, de falla de pod y de falla de instancia se ejecutaron y están documentadas en `docs/PRUEBAS.md`; la restauración de los respaldos no se probó.
