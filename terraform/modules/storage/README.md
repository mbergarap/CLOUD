# Módulo `storage`

> Documentación generada a partir de `variables.tf`, `outputs.tf` y `main.tf`.

## Recursos

- `aws_efs_file_system.redis`
- `aws_efs_mount_target.redis`
- `aws_backup_vault.redis`
- `aws_backup_plan.redis`
- `aws_backup_selection.redis`
- `aws_s3_bucket.etcd`
- `aws_s3_bucket_public_access_block.etcd`
- `aws_s3_bucket_server_side_encryption_configuration.etcd`
- `aws_s3_bucket_lifecycle_configuration.etcd`

## Variables

| Nombre | Tipo | Descripción | Valor por defecto |
|---|---|---|---|
| `nombre_proyecto` | `string` | "Prefijo usado en los nombres de los recursos." | obligatoria |
| `private_subnets` | `list(string)` | "Subredes privadas donde se crean los puntos de montaje EFS." | obligatoria |
| `efs_sg_id` | `string` | "Security Group de EFS." | obligatoria |

## Salidas

| Nombre | Descripción |
|---|---|
| `efs_id` | "Identificador del sistema de archivos EFS." |
| `etcd_bucket` | "Bucket S3 donde K3s guarda los snapshots de etcd." |
