
# DEFINE EL PREFIJO UTILIZADO PARA IDENTIFICAR LOS RECURSOS DE MONITOREO.
variable "nombre_proyecto" {
  description = "Prefijo usado en los nombres de los recursos."
  type        = string
}

# DEFINE LA REGION DE AWS DONDE SE CONFIGURAN LOS RECURSOS DE MONITOREO.
variable "region" {
  description = "Region de AWS."
  type        = string
}

# ESTABLECE EL CORREO ELECTRONICO QUE RECIBIRA LAS NOTIFICACIONES DE ALERTAS SNS.
variable "alerta_mail" {
  description = "Correo electronico que recibira las alertas SNS."
  type        = string
}

# IDENTIFICA EL BALANCEADOR ALB PARA CONSULTAR SUS METRICAS EN CLOUDWATCH.
variable "alb_arn_suffix" {
  description = "Sufijo del ARN del ALB (dimension LoadBalancer)."
  type        = string
}

# IDENTIFICA EL TARGET GROUP PARA MONITOREAR LA SALUD DE SUS DESTINOS.
variable "target_group_suffix" {
  description = "Sufijo del ARN del Target Group (dimension TargetGroup)."
  type        = string
}

# RECIBE LOS IDENTIFICADORES DE LAS INSTANCIAS K3S QUE SERAN MONITOREADAS.
variable "instance_ids" {
  description = "Identificadores de las tres instancias K3s."
  type        = list(string)
}

# IDENTIFICA EL GRUPO DE CLOUDWATCH LOGS UTILIZADO PARA CONSULTAR LOS REGISTROS DE K3S.
variable "log_group" {
  description = "Grupo de CloudWatch Logs de los nodos."
  type        = string
}

# PERMITE HABILITAR O DESHABILITAR LA RECUPERACION AUTOMATICA DE INSTANCIAS EC2.
variable "habilitar_recuperacion_ec2" {
  description = "Recupera la instancia automaticamente ante fallo del sistema (StatusCheckFailed_System)."
  type        = bool
  default     = true
}
