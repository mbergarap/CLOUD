
# =========================
# CONFIGURACION GENERAL
# =========================

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

# =========================
# BUCKET S3 DE LA APLICACION
# =========================

variable "app_bucket_name" {
  description = "Nombre del bucket S3 que almacena la aplicacion"
  type        = string
}
