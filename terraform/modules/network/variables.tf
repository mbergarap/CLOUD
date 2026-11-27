# DEFINE EL NOMBRE DEL PROYECTO PARA LOS RECURSOS DE RED.
variable "nombre_proyecto" {
  description = "Prefijo usado en los nombres de los recursos."
  type        = string
}

# DEFINE EL RANGO DE DIRECCIONES IP DE LA VPC.
variable "cidr_vpc" {
  description = "Bloque IP de la VPC."
  type        = string
}
