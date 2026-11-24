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

# CORREO PARA ALERTAS
variable "alerta_mail" {
  description = "Correo electronico que recibira las alertas SNS."
  type        = string
}

# BALANCEADOR
variable "alb_arn_suffix" {
  description = "Sufijo del ARN del ALB (dimension LoadBalancer)."
  type        = string
}

variable "target_group_suffix" {
  description = "Sufijo del ARN del Target Group (dimension TargetGroup)."
  type        = string
}

# INSTANCIAS
variable "instance_ids" {
  description = "Identificadores de las tres instancias K3s."
  type        = list(string)
}

# LOGS
variable "log_group" {
  description = "Grupo de CloudWatch Logs de los nodos."
  type        = string
}

# RECUPERACION AUTOMATICA
variable "habilitar_recuperacion_ec2" {
  description = "Recupera la instancia automaticamente ante fallo del sistema (StatusCheckFailed_System)."
  type        = bool
  default     = true
}
