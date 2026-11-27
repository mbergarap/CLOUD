
# DEFINE EL NOMBRE DEL PROYECTO PARA LOS RECURSOS DE ALMACENAMIENTO.
variable "nombre_proyecto" {
  description = "Prefijo usado en los nombres de los recursos."
  type        = string
}

# DEFINE LAS SUBREDES PRIVADAS DONDE SE CREAN LOS PUNTOS DE MONTAJE EFS.
variable "private_subnets" {
  description = "Subredes privadas donde se crean los puntos de montaje EFS."
  type        = list(string)
}

# RECIBE EL IDENTIFICADOR DEL GRUPO DE SEGURIDAD DE EFS.
variable "efs_sg_id" {
  description = "Security Group de EFS."
  type        = string
}

# DEFINE EL NOMBRE DEL BUCKET S3 PARA LOS RESPALDOS DE ETCD.
variable "nombre_bucket" {
  description = "Nombre del bucket S3 para los snapshots de etcd."
  type        = string
}
