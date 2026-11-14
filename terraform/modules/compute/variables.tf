
# =========================
# CONFIGURACION GENERAL
# =========================

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

# =========================
# RED Y SEGURIDAD
# =========================

variable "app_subnet_az1_id" {
  description = "ID de la subred privada de aplicaciones en AZ1"
  type        = string
}

variable "app_subnet_az2_id" {
  description = "ID de la subred privada de aplicaciones en AZ2"
  type        = string
}

variable "app_sg_id" {
  description = "ID del Security Group de las EC2 de aplicacion"
  type        = string
}

variable "key_name" {
  description = "Nombre de la clave SSH de las instancias EC2"
  type        = string
}

variable "target_group_arn" {
  description = "ARN del Target Group del Application Load Balancer"
  type        = string
}

# =========================
# S3 APLICACION
# =========================

variable "app_bucket_name" {
  description = "Nombre del bucket S3 que contiene la aplicacion Flask"
  type        = string
}

# =========================
# BASE DE DATOS
# =========================

variable "db_host" {
  description = "Direccion de la base de datos PostgreSQL"
  type        = string
}

variable "db_name" {
  description = "Nombre de la base de datos"
  type        = string
}

variable "db_user" {
  description = "Usuario de PostgreSQL"
  type        = string
}

variable "db_password" {
  description = "Contrasena de PostgreSQL"
  type        = string
  sensitive   = true
}

# =========================
# CLOUDWATCH LOGS
# =========================

variable "nginx_access_log_group" {
  description = "Grupo CloudWatch para logs de acceso de Nginx"
  type        = string
}

variable "nginx_error_log_group" {
  description = "Grupo CloudWatch para logs de error de Nginx"
  type        = string
}

variable "app_access_log_group" {
  description = "Grupo CloudWatch para logs de acceso de la aplicacion"
  type        = string
}

variable "app_error_log_group" {
  description = "Grupo CloudWatch para logs de error de la aplicacion"
  type        = string
}

# =========================
# IAM
# =========================

variable "instance_profile_name" {
  description = "Nombre del Instance Profile IAM asociado a las EC2"
  type        = string
  default     = "LabInstanceProfile"
}
