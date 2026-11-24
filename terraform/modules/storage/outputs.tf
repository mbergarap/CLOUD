# SISTEMA DE ARCHIVOS EFS
output "efs_id" {
  description = "Identificador del sistema de archivos EFS."
  value       = aws_efs_file_system.redis.id
}

# BUCKET S3 CREADO POR desplegar.ps1 MEDIANTE AWS CLI
output "etcd_bucket" {
  description = "Nombre calculado del bucket de snapshots de etcd."
  value       = "${var.nombre_proyecto}-etcd-${data.aws_caller_identity.current.account_id}"
}
