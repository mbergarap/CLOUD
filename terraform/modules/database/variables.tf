
# CONFIGURACION GENERAL

# Nombre utilizado para identificar los recursos de la base de datos.
variable "nombre_proyecto" {
  description = "Nombre del proyecto."
  type        = string
}

# RED Y SEGURIDAD

# Subredes privadas donde se despliega PostgreSQL.
variable "id_subred_bd_az1" {
  description = "ID de la subred de base de datos de AZ1."
  type        = string
}

variable "id_subred_bd_az2" {
  description = "ID de la subred de base de datos de AZ2."
  type        = string
}

# Security Group que controla el acceso a PostgreSQL.
variable "id_sg_rds" {
  description = "ID del Security Group de RDS."
  type        = string
}

# CREDENCIALES DE BASE DE DATOS

# Usuario administrador de PostgreSQL.
variable "usuario_bd" {
  description = "Usuario administrador de la base de datos."
  type        = string
  sensitive   = true
}

# Contrasena utilizada cuando RDS no la administra con Secrets Manager.
variable "contrasena_bd" {
  description = "Contrasena de PostgreSQL para AWS Academy."
  type        = string
  sensitive   = true
  default     = null
}

# Permite administrar la contrasena mediante Secrets Manager.
variable "administrar_contrasena_maestra" {
  description = "Indica si RDS administra la contrasena en Secrets Manager."
  type        = bool
  default     = false
}

# PROTECCION DE RDS

# Evita que la base de datos pueda eliminarse accidentalmente.
variable "proteccion_eliminacion" {
  description = "Activa la proteccion contra eliminacion de RDS."
  type        = bool
  default     = true
}
