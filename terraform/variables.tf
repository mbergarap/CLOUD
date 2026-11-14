
# =========================
# CONFIGURACION GENERAL
# =========================

variable "aws_region" {
  description = "Region de AWS"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "cloud-obligatorio"
}

# =========================
# BASE DE DATOS
# =========================

variable "db_username" {
  description = "Usuario administrador de PostgreSQL"
  type        = string
  default     = "cloudadmin"
  sensitive   = true
}

variable "db_password" {
  description = "Contrasena de PostgreSQL"
  type        = string
  sensitive   = true
}

variable "rds_deletion_protection" {
  description = "Habilita la proteccion contra eliminacion de RDS"
  type        = bool
  default     = true
}

# =========================
# MONITOREO
# =========================

variable "alert_email" {
  description = "Correo que recibira las alertas de CloudWatch"
  type        = string
}

# =========================
# BASTION Y SSH
# =========================

variable "ssh_public_key_path" {
  description = "Ruta local a la clave publica SSH"
  type        = string
}

variable "bastion_ami_id" {
  description = "AMI utilizada por el Bastion Host"
  type        = string
}

# =========================
# S3 APLICACION
# =========================

variable "app_bucket_name" {
  description = "Nombre unico del bucket S3 de la aplicacion"
  type        = string
}

# =========================
# IAM EC2
# =========================

variable "ec2_instance_profile_name" {
  description = "Nombre del perfil IAM utilizado por las EC2"
  type        = string
  default     = "LabInstanceProfile"
}


variable "create_iam_profile" {
  description = "Crear un perfil IAM propio o reutilizar uno existente"
  type        = bool
  default     = false
}