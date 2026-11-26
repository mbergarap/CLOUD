# SISTEMA DE ARCHIVOS EFS
output "efs_id" {
  description = "Identificador del sistema de archivos EFS."
  value       = aws_efs_file_system.redis.id
}

# BUCKET S3 CREADO POR TERRAFORM (AWS CLI, PARA COMPATIBILIDAD AWS ACADEMY)
output "etcd_bucket" {
  description = "Nombre calculado del bucket de snapshots de etcd."
  value       = var.nombre_bucket
}

