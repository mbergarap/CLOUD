# NOMBRE DEL PROYECTO
variable "nombre_proyecto" {
  description = "Prefijo usado en los nombres de los recursos."
  type        = string
}
# SUBREDES PRIVADAS
variable "private_subnets" {
  description = "Subredes privadas donde se crean los puntos de montaje EFS."
  type        = list(string)
}
# SEGURIDAD EFS
variable "efs_sg_id" {
  description = "Security Group de EFS."
  type        = string
}

# BUCKET DE SNAPSHOTS ETCD
variable "nombre_bucket" {
  description = "Nombre del bucket S3 para los snapshots de etcd."
  type        = string
}
