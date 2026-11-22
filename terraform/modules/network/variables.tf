# CONFIGURACION GENERAL

# Nombre utilizado para identificar los recursos de red.
variable "nombre_proyecto" {
  description = "Prefijo comun utilizado para nombrar los recursos."
  type        = string
}

# Rango de direcciones de la VPC.
variable "cidr_vpc" {
  description = "Bloque de direcciones IPv4 de la VPC."
  type        = string
}

# ZONAS DE DISPONIBILIDAD

# Zonas de disponibilidad utilizadas para distribuir la infraestructura.
variable "zona_disponibilidad_1" {
  description = "Primera zona de disponibilidad de AWS."
  type        = string
}

variable "zona_disponibilidad_2" {
  description = "Segunda zona de disponibilidad de AWS."
  type        = string
}

# SUBREDES PUBLICAS

# Direccionamiento de las subredes que alojan los recursos publicos.
variable "cidr_subred_publica_az1" {
  description = "Bloque CIDR de la subred publica de AZ1."
  type        = string
}

variable "cidr_subred_publica_az2" {
  description = "Bloque CIDR de la subred publica de AZ2."
  type        = string
}

# SUBREDES PRIVADAS DE APLICACION

# Subredes privadas donde funcionan la aplicacion y K3s.
variable "cidr_subred_app_az1" {
  description = "Bloque CIDR de la subred privada de aplicacion en AZ1."
  type        = string
}

variable "cidr_subred_app_az2" {
  description = "Bloque CIDR de la subred privada de aplicacion en AZ2."
  type        = string
}

# SUBREDES PRIVADAS DE BASE DE DATOS

# Subredes privadas destinadas a PostgreSQL RDS.
variable "cidr_subred_bd_az1" {
  description = "Bloque CIDR de la subred privada de base de datos en AZ1."
  type        = string
}

variable "cidr_subred_bd_az2" {
  description = "Bloque CIDR de la subred privada de base de datos en AZ2."
  type        = string
}