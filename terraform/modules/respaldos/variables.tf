
# CONFIGURACION GENERAL

variable "nombre_proyecto" {
  description = "Nombre del proyecto."
  type        = string
}

# IAM

variable "nombre_rol_iam" {
  description = "Rol IAM utilizado por AWS Backup (en AWS Academy: LabRole)."
  type        = string
  default     = "LabRole"
}

# PLAN

variable "programacion" {
  description = "Expresion cron del respaldo (UTC)."
  type        = string
  default     = "cron(0 5 * * ? *)"
}

variable "dias_retencion" {
  description = "Dias que se conserva cada respaldo."
  type        = number
  default     = 14
}

variable "arns_recursos" {
  description = "ARNs de recursos a respaldar (ej: RDS)."
  type        = list(string)
  default     = []
}
