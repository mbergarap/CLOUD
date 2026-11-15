
# CONFIGURACION GENERAL

# Nombre utilizado para identificar los recursos del Bastion.
variable "nombre_proyecto" {
  description = "Nombre del proyecto."
  type        = string
}

# RED Y SEGURIDAD

# Subred publica donde se crea el Bastion.
variable "id_subred_publica" {
  description = "ID de la subred publica."
  type        = string
}

# Security Group que controla las conexiones SSH.
variable "id_sg_bastion" {
  description = "ID del Security Group del Bastion."
  type        = string
}

# ACCESO SSH

# Ruta de la clave publica utilizada para conectarse a las instancias.
variable "ruta_clave_publica_ssh" {
  description = "Ruta del archivo de clave publica SSH."
  type        = string
}

# INSTANCIA EC2

# Imagen de Amazon Linux utilizada para crear el Bastion.
variable "id_ami" {
  description = "ID de la AMI utilizada por el Bastion."
  type        = string
}
