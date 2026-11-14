variable "project_name" {
  type = string
}

variable "bucket_name" {
  type = string
}

variable "app_source_dir" {
  description = "Directorio que contiene la aplicacion"
  type        = string
}

variable "app_zip_path" {
  description = "Ruta donde se genera app.zip"
  type        = string
}