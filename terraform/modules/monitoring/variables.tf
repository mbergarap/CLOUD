# CONFIGURACION GENERAL

# Nombre utilizado para identificar los recursos de monitoreo.
variable "nombre_proyecto" {
  description = "Nombre del proyecto."
  type        = string
}

# NOTIFICACIONES

# Correo donde recibimos las alertas del sistema.
variable "correo_alertas" {
  description = "Direccion de correo para las notificaciones."
  type        = string
}

# KUBERNETES K3S

# Identificadores de las instancias EC2 del cluster K3s.
variable "ids_instancias_k3s" {
  description = "IDs de las instancias EC2 utilizadas por K3s."
  type        = list(string)
  default     = []
}

# BASE DE DATOS

# Identificador de RDS utilizado en las alarmas de CloudWatch.
variable "identificador_instancia_bd" {
  description = "Identificador de la instancia PostgreSQL RDS."
  type        = string
}

# AUTOESCALADO

# Nombre del Auto Scaling Group de workers (dimension de CloudWatch).
variable "nombre_asg_workers" {
  description = "Nombre del Auto Scaling Group de workers K3s."
  type        = string
}

# LOGS

# Log group donde los nodos envian los logs de los pods.
variable "nombre_grupo_logs" {
  description = "Nombre del log group de CloudWatch."
  type        = string
}

variable "dias_retencion_logs" {
  description = "Dias de retencion de los logs."
  type        = number
  default     = 14
}

# BALANCEADOR DE CARGA

variable "sufijo_arn_alb" {
  description = "Sufijo del ARN del ALB."
  type        = string
}

variable "sufijo_arn_destino" {
  description = "Sufijo del ARN del Target Group."
  type        = string
}

variable "region_aws" {
  description = "Region de AWS (para el dashboard)."
  type        = string
  default     = "us-east-1"
}
