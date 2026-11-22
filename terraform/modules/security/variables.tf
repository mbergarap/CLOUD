
# CONFIGURACION GENERAL

# Nombre del proyecto utilizado para identificar los recursos.
variable "nombre_proyecto" {
  description = "Nombre utilizado como prefijo de los recursos."
  type        = string
}

# VPC donde se crean los Security Groups.
variable "id_vpc" {
  description = "ID de la VPC."
  type        = string
}

# ACCESO SSH AL BASTION

# Solo permitimos el acceso SSH desde una direccion IP especifica.
variable "cidr_ssh_bastion" {
  description = "Direccion IPv4 autorizada para acceder al Bastion por SSH."
  type        = string

  validation {
    condition     = can(cidrhost(var.cidr_ssh_bastion, 0)) && endswith(var.cidr_ssh_bastion, "/32")
    error_message = "Se requiere una direccion IPv4 individual con mascara /32."
  }
}
