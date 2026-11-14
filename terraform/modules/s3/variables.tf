
# =========================
# CONFIGURACION GENERAL
# =========================

variable "project_name" {
  type = string
}

variable "bucket_name" {
  description = "Nombre unico del bucket S3 de la aplicacion"
  type        = string
}

# =========================
# ARCHIVOS DE LA APLICACION
# =========================

variable "app_source_dir" {
  description = "Directorio que contiene la aplicacion"
  type        = string
}

variable "app_zip_path" {
  description = "Ruta donde se genera app.zip"
  type        = string
}

# =========================
# MODO DE CREACION S3
# =========================

variable "use_native_s3" {
  description = "true: recursos Terraform nativos. false: AWS CLI para AWS Academy"
  type        = bool
  default     = false
}

# =========================
# REGION
# =========================

variable "aws_region" {
  description = "Region donde se crea el bucket"
  type        = string
  default     = "us-east-1"
}
