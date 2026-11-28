# Compatibilidad con AWS Academy y estado de validacion

Esta variante se despliega con cuatro comandos Terraform, con estado local. Las EC2 se configuran solas con `user_data` y una asociación de SSM verifica el resultado.

## Restricciones conocidas

- La politica SCP de AWS Academy denego `s3:GetBucketObjectLockConfiguration` cuando Terraform administraba el bucket de etcd. Por eso el bucket de snapshots no es un recurso `aws_s3_bucket`: lo crea el `user_data` del nodo principal con AWS CLI y el rol de la instancia. Esta ruta no necesita bucket de backend, porque usa estado local.
- La creacion de bucket S3 para logs de ALB con Terraform **no se habilita**.
- La recuperacion automatica de EC2 se deja deshabilitada por defecto hasta validar cuotas y permisos.
- Los snapshots etcd locales se generan mediante K3s; una unidad/timer `systemd` intenta subirlos a S3 independientemente del arranque. La subida depende de `LabRole` y debe verificarse de verdad.
- Las alarmas, los logs del agente y algunos recursos adicionales podrian estar limitados por las politicas de AWS Academy.

## Estado de verificacion

El proyecto anterior tuvo un despliegue exitoso desde cuenta reiniciada. La variante con cuatro comandos tuvo un despliegue con respuesta HTTP 200 y tres targets sanos. Esto no equivale a validar restauraciones, monitoreo completo ni recuperacion ante fallos.

## Antes de desplegar

Si la cuenta contiene infraestructura parcialmente aplicada por la variante anterior, no correr `terraform destroy` ni resetear por defecto: revisar `terraform plan` y migracion del estado. La versión actual define las reglas de Security Groups como recursos independientes: revisar `terraform plan` (puede mostrar eliminaciones de reglas) antes de aplicar.

## Despliegue nuevo

1. Configurar AWS CLI v2 para una cuenta AWS Academy limpia.
2. Ingresar en `terraform/` y ejecutar `terraform init`, `terraform validate`, `terraform plan`, `terraform apply`.
3. Crear `terraform.tfvars` a partir de `terraform.tfvars.example` y completar correo SNS y nombre del bucket (único en todo S3; se sugiere terminarlo con el ID de cuenta). Revisar el plan antes de aplicar.
4. Al terminar, corroborar ALB HTTP 200, nodos Ready, distribución entre AZ, snapshots, SNS y backup.
5. No sustituir la prueba real de restauración EFS por el solo hecho de disponer de un plan AWS Backup.

El estado local debe quedar fuera del repositorio y en una ubicación protegida. No mezclar con un despliegue anterior que use estado S3.

No publicar tokens K3s, contraseñas, estado Terraform ni `config.psd1`.
