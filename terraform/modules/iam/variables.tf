# =========================
# CONFIGURACION GENERAL
# =========================

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

# =========================
# BUCKET S3
# =========================

variable "app_bucket_name" {
  description = "Bucket que contiene app.zip"
  type        = string
}

# =========================
# SECRETS MANAGER
# =========================

variable "db_secret_arn" {
  description = "ARN del secreto administrado por RDS"
  type        = string
  default     = null
}