# Obligatorio – Implementación de Soluciones Cloud (ISC-N5A)

Despliegue automatizado de **Online Boutique** (e-commerce de microservicios) en AWS con **Terraform** y **K3s**, pensado para soportar picos de tráfico y la caída de una zona de disponibilidad.

**Estado:** la versión base se desplegó y verificó desde una cuenta AWS Academy reiniciada el 23/11/2026 (3 nodos Ready, microservicios disponibles, HTTP 200 por el ALB). Esta versión ampliada (logs en CloudWatch, alarmas adicionales, Security Groups como recursos independientes, HPA/PDB en microservicios) **todavía no pasó un despliegue integral desde cero**. Restricciones y límites de AWS Academy en [`docs/COMPATIBILIDAD-AWS-ACADEMY.md`](docs/COMPATIBILIDAD-AWS-ACADEMY.md); registro de pruebas en [`docs/PRUEBAS.md`](docs/PRUEBAS.md).

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
| [`docs/MEJORAS-INTEGRADAS.md`](docs/MEJORAS-INTEGRADAS.md) | Qué mejoras se integraron y cuáles no |
| [`docs/PRUEBAS.md`](docs/PRUEBAS.md) | Pruebas de carga y de fallas (procedimiento y registro de resultados) |
| `terraform/modules/*/README.md` | Recursos, variables y salidas de cada módulo |

## Inicio rápido

1. Instalar los requisitos (tabla siguiente) y configurar credenciales de AWS Academy.
2. (Opcional) copiar `config.example.psd1` a `config.psd1` con `alerta_mail` y `nombre_bucket`. Si no existe, el script pide el correo y calcula el nombre del bucket de estado.
3. Ejecutar `.\validar.ps1` y luego `.\desplegar.ps1`.
4. Al terminar, el script imprime la URL pública de Online Boutique.

Más detalle en [`docs/OPERACION.md`](docs/OPERACION.md).

## Requisitos y versiones

| Componente | Versión |
|---|---|
| Windows PowerShell | 5.1 o PowerShell 7 |
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
| `desplegar.ps1`, `validar.ps1` | Automatización del despliegue y validaciones previas |
| `.github/workflows/terraform.yml` | CI: `fmt` y `validate` |

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

`desplegar.ps1` puede ejecutarse sin `config.psd1`: solicita correo SNS, una IP publica /32 de referencia (SSH permanece cerrado por seguridad) y genera el nombre del backend S3 a partir de la cuenta AWS. Para cuentas con estado previo, conservar el mismo nombre de bucket en `config.psd1`. El bucket de snapshots etcd se administra con AWS CLI y no Terraform, debido a un rechazo SCP de Object Lock registrado en AWS Academy. Los snapshots se generan localmente y se intentan sincronizar a S3 mediante un temporizador independiente para no bloquear el inicio de K3s. La copia remota y esta variante ampliada requieren pruebas reales.
