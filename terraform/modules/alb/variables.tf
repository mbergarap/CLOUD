
# CONFIGURACION GENERAL

# Nombre utilizado para identificar los recursos del balanceador.
variable "nombre_proyecto" {
  description = "Nombre del proyecto."
  type        = string
}

# RED

# VPC donde se encuentra el balanceador.
variable "id_vpc" {
  description = "ID de la VPC."
  type        = string
}

# Subredes publicas donde se distribuye el ALB.
variable "id_subred_publica_az1" {
  description = "ID de la subred publica de AZ1."
  type        = string
}

variable "id_subred_publica_az2" {
  description = "ID de la subred publica de AZ2."
  type        = string
}

# SEGURIDAD

# Security Group que controla las conexiones del balanceador.
variable "id_sg_alb" {
  description = "ID del Security Group del ALB."
  type        = string
}
