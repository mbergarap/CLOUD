
# EXPONE EL IDENTIFICADOR DEL SISTEMA EFS UTILIZADO PARA EL ALMACENAMIENTO PERSISTENTE DE REDIS.
output "efs_id" {
  description = "Identificador del sistema de archivos EFS."
  value       = aws_efs_file_system.redis.id
}

# EXPONE EL NOMBRE DEL BUCKET S3 UTILIZADO PARA ALMACENAR LOS SNAPSHOTS DE ETCD.
output "etcd_bucket" {
  description = "Nombre del bucket S3 para los snapshots de etcd."
  value       = var.nombre_bucket
}
