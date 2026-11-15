
# CONFIGURACION GENERAL

# Nombre utilizado para identificar los recursos de la aplicacion.
variable "nombre_proyecto" {
  description = "Nombre del proyecto."
  type        = string
}

# RED Y SEGURIDAD

# Subredes privadas donde se ejecutan las instancias EC2.
variable "id_subred_app_az1" {
  description = "ID de la subred de aplicacion de AZ1."
  type        = string
}

variable "id_subred_app_az2" {
  description = "ID de la subred de aplicacion de AZ2."
  type        = string
}

# Security Group utilizado por las instancias de aplicacion.
variable "id_sg_app" {
  description = "ID del Security Group de las EC2 de aplicacion."
  type        = string
}

# Clave SSH utilizada para administrar las instancias.
variable "nombre_clave_ssh" {
  description = "Nombre de la clave SSH registrada en AWS."
  type        = string
}

# Grupo de destino donde el ALB envia las solicitudes.
variable "arn_grupo_destino" {
  description = "ARN del Target Group del balanceador."
  type        = string
}

# ALMACENAMIENTO S3

# Bucket que contiene el archivo app.zip.
variable "nombre_bucket_aplicacion" {
  description = "Nombre del bucket S3 de la aplicacion."
  type        = string
}

# BASE DE DATOS

# Direccion utilizada para conectarse a PostgreSQL.
variable "servidor_bd" {
  description = "Direccion de PostgreSQL RDS."
  type        = string
}

variable "nombre_bd" {
  description = "Nombre de la base de datos."
  type        = string
}

variable "usuario_bd" {
  description = "Usuario de PostgreSQL."
  type        = string
}

# Contrasena utilizada para la conexion con PostgreSQL.
variable "contrasena_bd" {
  description = "Contrasena de PostgreSQL."
  type        = string
  sensitive   = true
}

# CLOUDWATCH LOGS

# Grupos donde se almacenan los registros de Nginx.
variable "grupo_logs_acceso_nginx" {
  description = "Grupo de registros de acceso de Nginx."
  type        = string
}

variable "grupo_logs_error_nginx" {
  description = "Grupo de registros de errores de Nginx."
  type        = string
}

# Grupos donde se almacenan los registros de la aplicacion.
variable "grupo_logs_acceso_app" {
  description = "Grupo de registros de acceso de la aplicacion."
  type        = string
}

variable "grupo_logs_error_app" {
  description = "Grupo de registros de errores de la aplicacion."
  type        = string
}

# IAM

# Perfil IAM asociado a las instancias EC2.
variable "nombre_perfil_instancia" {
  description = "Nombre del Instance Profile utilizado por las EC2."
  type        = string
  default     = "LabInstanceProfile"
}

# SECRETS MANAGER

# Indica si RDS administra la contrasena mediante Secrets Manager.
variable "administrar_contrasena_maestra" {
  description = "Permite utilizar una contrasena administrada por RDS."
  type        = bool
  default     = false
}

# ARN del secreto utilizado para obtener las credenciales.
variable "arn_secreto_bd" {
  description = "ARN del secreto de PostgreSQL en Secrets Manager."
  type        = string
  default     = null
}
