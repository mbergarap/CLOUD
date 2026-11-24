# NOMBRE DEL PROYECTO
variable "nombre_proyecto" {
  description = "Prefijo usado en los nombres de los recursos."
  type        = string
}

# CIDR DE LA VPC
variable "cidr_vpc" {
  description = "Bloque CIDR de la VPC."
  type        = string
}
