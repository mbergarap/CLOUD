
# CONFIGURACION GENERAL

# Nombre del proyecto utilizado para identificar los recursos.
variable "nombre_proyecto" {
  description = "Nombre del proyecto."
  type        = string
}

# BUCKET S3

# Bucket donde se encuentra el archivo de la aplicacion.
variable "nombre_bucket_aplicacion" {
  description = "Nombre del bucket S3 que contiene app.zip."
  type        = string
}

# SECRETS MANAGER

# Secreto que contiene las credenciales de la base de datos.
variable "arn_secreto_bd" {
  description = "ARN del secreto de RDS en Secrets Manager."
  type        = string
  default     = null
}
