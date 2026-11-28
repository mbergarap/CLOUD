# Operación

## Despliegue

**Requiere cuenta AWS Academy limpia** (no reutilizar una cuenta con infraestructura Terraform anterior). Hace falta Terraform y credenciales de AWS configuradas (AWS CLI v2).

Desde la raíz del repositorio:

```powershell
cd terraform
terraform init
terraform validate
terraform plan
terraform apply
```

Antes, copiar `terraform.tfvars.example` como `terraform.tfvars` y completar `alerta_mail` y `nombre_bucket`. El nombre del bucket debe ser único en todo S3 y cumplir sus reglas (3 a 63 caracteres, minúsculas, números, puntos y guiones); Terraform lo valida. Si el nombre ya existe en otra cuenta, el arranque del nodo principal falla al crearlo.

Durante `apply`, el `user_data` de cada EC2 instala K3s y etiqueta su zona de disponibilidad. El nodo principal además crea el bucket de snapshots (con el rol de la instancia: bloqueo público, cifrado AES256 y retención de 7 días) y aplica `kubernetes/app.yaml`, que Terraform entrega comprimido. Después, `aws_ssm_association.verificar_kubernetes` comprueba por SSM 3 nodos `Ready`, 2 réplicas del frontend y HTTP 200 por el ALB. **No hay un backend remoto S3 en esta modalidad.**

La ruta se probó con un `apply` real y acceso HTTP 200; respaldos, restauraciones y observabilidad deben verificarse por separado.

**Estado local:** conservar `terraform.tfstate`, controlar el acceso a la PC y mantenerlo fuera de Git. El token del clúster puede aparecer en el estado. El bucket de snapshots queda fuera del estado y no se borra con `terraform destroy`; gestionar su limpieza solo después de aprobarla.

**No mezclar flujos:** esta variante usa estado local; nunca ejecutarla sobre infraestructura administrada con otro estado sin un procedimiento de migración.

## Variables de Terraform (`terraform/variables.tf`)

Todas las variables tienen reglas de validación: Terraform rechaza el `plan` con un mensaje claro si un valor no es válido (correo, nombre del proyecto, región, CIDR, tipo de instancia, versión de K3s, retención de logs y nombre del bucket).

| Variable | Defecto | Descripción |
|---|---|---|
| `alerta_mail` | (obligatoria) | Correo de alertas SNS; definir en `terraform.tfvars` |
| `nombre_bucket` | (obligatoria) | Nombre del bucket de snapshots de etcd, único en todo S3 (se sugiere terminarlo con el ID de cuenta) |
| `nombre_proyecto` | `isc-obligatorio` | Prefijo de nombres |
| `region` | `us-east-1` | Región |
| `cidr_vpc` | `192.168.0.0/16` | CIDR de la VPC |
| `tipo_instancia` | `t3.medium` | Tipo de EC2 |
| `version_k3s` | `v1.37.2+k3s1` | Versión de K3s (vacío = última) |
| `dias_retencion_logs` | `14` | Retención de logs |
| `habilitar_recuperacion_ec2` | `false` | Recuperación automática de EC2 (activar solo si AWS Academy lo permite) |

> Los scripts de `pruebas/` buscan recursos con el prefijo `isc-obligatorio`: si se cambia `nombre_proyecto`, ajustarlos también.

## Ya existe un despliegue anterior

**No ejecutar la variante de estado local contra la cuenta existente con estado S3.** El estado local vacío no reconoce los recursos antiguos y el plan podría mostrar creaciones duplicadas. La migración de backend requiere primero estudiar el estado remoto, los recursos y el procedimiento de migración. No eliminar ni sobrescribir el S3 anterior.

## Comandos útiles

```bash
aws ssm start-session --target <id-instancia>   # acceso sin SSH
sudo k3s kubectl get nodes,pods -o wide
sudo k3s kubectl get hpa,pdb
```
