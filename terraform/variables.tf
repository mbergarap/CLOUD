# CORREO PARA ALERTAS
variable "alerta_mail" {
  description = "Correo electronico que recibira las alertas SNS."
  type        = string
  validation {
    condition     = can(regex("^[^\\s@'\"]+@[^\\s@'\"]+\\.[^\\s@'\"]+$", var.alerta_mail))
    error_message = "Ingresa un correo SNS valido sin espacios ni comillas."
  }
}

# NOMBRE DEL PROYECTO
variable "nombre_proyecto" {
  description = "Prefijo usado en los nombres de los recursos."
  type        = string
  default     = "isc-obligatorio"
}

# REGION
variable "region" {
  description = "Region de AWS donde se despliega la infraestructura."
  type        = string
  default     = "us-east-1"
}

# RED
variable "cidr_vpc" {
  description = "Bloque CIDR de la VPC. Las subredes se calculan a partir de este bloque."
  type        = string
  default     = "10.80.0.0/16"
}

# COMPUTO
variable "tipo_instancia" {
  description = "Tipo de instancia EC2 de los tres servidores K3s."
  type        = string
  default     = "t3.medium"
}

variable "version_k3s" {
  description = "Version de K3s a instalar (ej. v1.37.2+k3s1). Vacio instala la ultima disponible."
  type        = string
  default     = "v1.37.2+k3s1"
}

# LOGS Y MONITOREO
variable "dias_retencion_logs" {
  description = "Dias de retencion de logs en CloudWatch."
  type        = number
  default     = 14
}


variable "habilitar_recuperacion_ec2" {
  description = "Alarma que recupera automaticamente una instancia ante fallo de hardware (StatusCheckFailed_System)."
  type        = bool
  default     = false
}

# BUCKET DE SNAPSHOTS ETCD
variable "nombre_bucket" {
  description = "Nombre del bucket S3 para los snapshots de etcd."
  type        = string
}
