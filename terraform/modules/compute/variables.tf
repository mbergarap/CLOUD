# NOMBRE DEL PROYECTO
variable "nombre_proyecto" {
  description = "Prefijo usado en los nombres de los recursos."
  type        = string
}

# REGION
variable "region" {
  description = "Region de AWS."
  type        = string
}

# TIPO DE INSTANCIA
variable "tipo_instancia" {
  description = "Tipo de instancia EC2 de los servidores K3s."
  type        = string
}

# VERSION DE K3S
variable "version_k3s" {
  description = "Version de K3s. Vacio instala la ultima disponible."
  type        = string
}

# SUBREDES PUBLICAS
variable "public_subnets" {
  description = "Subredes publicas del ALB."
  type        = list(string)
}

# SUBREDES PRIVADAS
variable "private_subnets" {
  description = "Subredes privadas de los servidores K3s."
  type        = list(string)
}

# SEGURIDAD KUBERNETES
variable "k3s_sg_id" {
  description = "Security Group de los nodos K3s."
  type        = string
}

# SEGURIDAD BALANCEADOR
variable "alb_sg_id" {
  description = "Security Group del ALB."
  type        = string
}

# VPC
variable "vpc_id" {
  description = "Identificador de la VPC."
  type        = string
}

# BUCKET DE RESPALDOS ETCD
variable "etcd_bucket" {
  description = "Bucket S3 de snapshots de etcd."
  type        = string
}

# LOGS
variable "log_group" {
  description = "Grupo de CloudWatch Logs donde el agente envia los logs."
  type        = string
}
