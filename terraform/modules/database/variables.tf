
# =========================
# CONFIGURACION GENERAL
# =========================

variable "project_name" {
  type = string
}

# =========================
# RED Y SEGURIDAD
# =========================

variable "db_subnet_az1_id" {
  type = string
}

variable "db_subnet_az2_id" {
  type = string
}

variable "rds_sg_id" {
  type = string
}

# =========================
# CREDENCIALES DATABASE
# =========================

variable "db_username" {
  type      = string
  sensitive = true
}

variable "db_password" {
  description = "Password utilizado en AWS Academy"
  type        = string
  sensitive   = true
  default     = null
}

variable "manage_master_user_password" {
  description = "Permitir que RDS administre la contraseña en Secrets Manager"
  type        = bool
  default     = false
}

# =========================
# PROTECCION RDS
# =========================

variable "deletion_protection" {
  description = "Habilita la proteccion contra eliminacion de RDS"
  type        = bool
  default     = true
}
