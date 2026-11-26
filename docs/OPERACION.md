# Operación

## Despliegue sin `desplegar.ps1`

**Requiere cuenta AWS Academy limpia** (no reutilizar la cuenta que tiene infraestructura Terraform remota anterior). Se trabaja en Windows con PowerShell 5.1+ y AWS CLI v2.

Desde la raíz del repositorio:

```powershell
cd terraform
terraform init
terraform validate
terraform plan
terraform apply
```

Antes de ejecutar Terraform, copiar `terraform.tfvars.example` como `terraform.tfvars`, completar `alerta_mail` y `nombre_bucket` y verificar que el nombre del bucket termine en el ID AWS activo de 12 dígitos. Durante `apply`, el recurso `terraform_data.bucket_etcd` invoca `scripts/crear-bucket-etcd.ps1` para preparar el bucket S3 de snapshots mediante AWS CLI (evitando Object Lock, que una SCP de AWS Academy deniega). `module.compute` espera ese recurso antes de iniciar las EC2. El recurso `terraform_data.finalizar_kubernetes` espera Terraform y, mediante SSM, comprueba K3s, etiqueta AZ, aplica `kubernetes/app.yaml` con EFS, verifica Redis y los HPA/PDB, monitoreo y acceso HTTP por ALB. **No hay un backend remoto S3 en esta modalidad.**

No es un despliegue puramente declarativo: Terraform utiliza provisioners y la ejecución local de AWS CLI como transición por restricciones del laboratorio. El operador no necesita correrlos por separado. La ruta fue probada con un `apply` real y acceso HTTP 200; respaldos, restauraciones y observabilidad deben verificarse por separado.

**Estado local:** conservar `terraform.tfstate`, controlar acceso a la PC y mantenerlo fuera de Git. El token del clúster puede aparecer en el estado. Los snapshots etcd en S3 permanecen fuera del estado, y no se borran al ejecutar `terraform destroy`; gestionar su limpieza solo después de aprobarla.

**No mezclar flujos:** esta variante usa estado local; nunca ejecutar sobre infraestructura administrada mediante otro estado sin un procedimiento específico de migración. No crear recursos duplicados en una cuenta que ya contenga recursos del obligatorio.

## Variables de Terraform (`terraform/variables.tf`)

| Variable | Defecto | Descripción |
|---|---|---|
| `alerta_mail` | (obligatoria) | Correo de alertas SNS; definir en `terraform.tfvars` |
| `nombre_bucket` | (obligatoria) | Nombre de bucket etcd único, terminado en el ID de cuenta AWS |
| `nombre_proyecto` | `isc-obligatorio` | Prefijo de nombres |
| `region` | `us-east-1` | Región |
| `cidr_vpc` | `10.80.0.0/16` | CIDR de la VPC |
| `tipo_instancia` | `t3.medium` | Tipo de EC2 |
| `version_k3s` | `v1.37.2+k3s1` | Versión de K3s (vacío = última) |
| `dias_retencion_logs` | `14` | Retención de logs |
| `habilitar_recuperacion_ec2` | `false` | Recuperación automática de EC2 | (activar solo si AWS Academy lo permite)

> Mantener el prefijo de proyecto predeterminado salvo que también se revisen las referencias utilizadas por los scripts y las alarmas.

## Ya existe un despliegue anterior

**No ejecutar la variante de estado local contra la cuenta existente con estado S3.** El estado local vacío no reconoce los recursos antiguos y el plan podría mostrar creaciones duplicadas. La migración de backend requiere primero estudiar el estado remoto, los recursos y el procedimiento de migración. No eliminar ni sobrescribir el S3 anterior.

## Comandos útiles

```bash
aws ssm start-session --target <id-instancia>   # acceso sin SSH
sudo k3s kubectl get nodes,pods -o wide
sudo k3s kubectl get hpa,pdb
```
