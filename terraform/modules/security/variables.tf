# NOMBRE DEL PROYECTO
variable "nombre_proyecto" {
  description = "Prefijo usado en los nombres de los recursos."
  type        = string
}

# VPC
variable "vpc_id" {
  description = "Identificador de la VPC."
  type        = string
}

# CIDR DE LA VPC (solo para el DNS interno)
variable "cidr_vpc" {
  description = "Bloque CIDR de la VPC."
  type        = string
}
