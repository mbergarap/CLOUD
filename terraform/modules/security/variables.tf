## DEFINE EL NOMBRE DEL PROYECTO PARA LOS RECURSOS DE SEGURIDAD.
variable "nombre_proyecto" {
  description = "Prefijo usado en los nombres de los recursos."
  type        = string
}

# RECIBE EL IDENTIFICADOR DE LA VPC.
variable "vpc_id" {
  description = "Identificador de la VPC."
  type        = string
}

# DEFINE EL RANGO DE DIRECCIONES IP DE LA VPC.
variable "cidr_vpc" {
  description = "Bloque IP de la VPC."
  type        = string
}
