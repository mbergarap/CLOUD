
# Nombre del bucket donde se almacena la aplicacion.
output "nombre_bucket" {
  description = "Nombre del bucket S3 de la aplicacion."
  value       = var.nombre_bucket
}

# ARN del bucket, utilizado para identificarlo en AWS.
output "arn_bucket" {
  description = "ARN del bucket S3 de la aplicacion."
  value       = "arn:aws:s3:::${var.nombre_bucket}"
}
