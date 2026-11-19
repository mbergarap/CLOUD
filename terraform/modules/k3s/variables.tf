
# CONFIGURACION GENERAL

# Nombre utilizado para identificar los recursos del cluster.
variable "nombre_proyecto" {
  description = "Nombre del proyecto."
  type        = string
}

# RED Y SEGURIDAD

# VPC donde se encuentran los nodos Kubernetes.
variable "id_vpc" {
  description = "ID de la VPC."
  type        = string
}

# Subredes privadas donde se distribuyen los nodos.
variable "id_subred_app_az1" {
  description = "ID de la subred de aplicacion de AZ1."
  type        = string
}

variable "id_subred_app_az2" {
  description = "ID de la subred de aplicacion de AZ2."
  type        = string
}

# Security Group del Bastion utilizado para el acceso SSH.
variable "id_sg_bastion" {
  description = "ID del Security Group del Bastion."
  type        = string
}

# Security Group del ALB utilizado para acceder a Online Boutique.
variable "id_sg_alb" {
  description = "ID del Security Group del ALB."
  type        = string
}

# ACCESO SSH

# Clave utilizada para conectarnos a los nodos.
variable "nombre_clave_ssh" {
  description = "Nombre de la clave SSH registrada en AWS."
  type        = string
}

# INSTANCIAS K3S

# Tipo de EC2 utilizado para el servidor principal.
variable "tipo_instancia_servidor" {
  description = "Tipo de instancia EC2 del servidor K3s."
  type        = string
  default     = "t3.medium"
}

# Tipo de EC2 utilizado para los workers.
variable "tipo_instancia_worker" {
  description = "Tipo de instancia EC2 de los workers K3s."
  type        = string
  default     = "t3.small"
}

# IAM

# Perfil IAM utilizado por las instancias del cluster.
variable "nombre_perfil_instancia" {
  description = "Nombre del Instance Profile utilizado por K3s."
  type        = string
}
