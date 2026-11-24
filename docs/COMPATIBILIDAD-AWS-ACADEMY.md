# Compatibilidad con AWS Academy y estado de validacion

Esta variante toma mejoras del ZIP de propuestas y mantiene como prioridad el despliegue con `desplegar.ps1`.

## Restricciones conocidas

- La politica SCP de AWS Academy denego `s3:GetBucketObjectLockConfiguration` cuando Terraform administraba el bucket de etcd. Los buckets de backend y snapshots se crean mediante AWS CLI, fuera del estado de Terraform.
- La creacion de bucket S3 para logs de ALB con Terraform **no se habilita**.
- La recuperacion automatica de EC2 se deja deshabilitada por defecto hasta validar cuotas y permisos.
- Los snapshots etcd locales se generan mediante K3s; una unidad/timer `systemd` intenta subirlos a S3 independientemente del arranque. La subida depende de `LabRole` y debe verificarse de verdad.
- Las alarmas, los logs del agente y algunos recursos adicionales podrian estar limitados por las politicas de AWS Academy.

## Estado de verificacion

El proyecto anterior tuvo un despliegue exitoso desde cuenta reiniciada. **Esta variante ampliada no ha pasado aun un despliegue integral desde cero.** Validaciones estaticas no equivalen a un `apply` real.

## Antes de desplegar

Si la cuenta contiene infraestructura parcialmente aplicada por la variante anterior, no correr `terraform destroy` ni resetear por defecto: revisar `terraform plan` y migracion del estado. La nueva version reorganiza reglas de Security Groups; el script bloquea eliminaciones/reemplazos.

## Despliegue nuevo

1. Preparar AWS CLI y Terraform en PowerShell.
2. `config.psd1` es opcional: si no existe, el script solicita el correo SNS y calcula el bucket backend desde la cuenta AWS. Solicita tambien una IP /32 para futuras politicas SSH; SSH esta deshabilitado y la administracion utiliza SSM.
3. Ejecutar `./desplegar.ps1` (en PowerShell ` .\desplegar.ps1`).
4. Validar ALB HTTP 200, nodos Ready, Redis/EFS, la salida de la etapa snapshots y los archivos de `s3://isc-obligatorio-etcd-<cuenta>/snapshots/`.
5. Verificar AWS Backup recuperable en una ventana posterior; el plan solo no prueba la restauracion.

No publicar tokens K3s, contraseñas, estado Terraform ni `config.psd1`.
