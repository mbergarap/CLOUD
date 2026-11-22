variable "nombre_bucket_estado" {
  description = "Nombre del bucket S3 utilizado para el estado remoto de Terraform."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.nombre_bucket_estado))
    error_message = "El nombre debe ser valido para un bucket S3."
  }
}