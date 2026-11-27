# CONFIGURA Y VALIDA EL CORREO DE DESTINO PARA LAS ALERTAS DEL MONITOREO.
variable "alerta_mail" {
  description = "Correo electronico que recibira las alertas SNS."
  type        = string
  validation {
    condition     = can(regex("^[^\\s@'\"]+@[^\\s@'\"]+\\.[^\\s@'\"]+$", var.alerta_mail))
    error_message = "Ingresa un correo SNS valido sin espacios ni comillas."
  }
}

# DEFINE EL NOMBRE UTILIZADO PARA IDENTIFICAR LOS RECURSOS.
variable "nombre_proyecto" {
  description = "Prefijo usado en los nombres de los recursos."
  type        = string
  default     = "isc-obligatorio"
}

# DEFINE LA REGIÓN DE AWS PARA EL DESPLIEGUE.
variable "region" {
  description = "Region de AWS donde se despliega la infraestructura."
  type        = string
  default     = "us-east-1"
}

# DEFINE EL RANGO DE DIRECCIONES IP DE LA VPC.
variable "cidr_vpc" {
  description = "Bloque ip de la VPC. Las subredes se calculan a partir de este bloque."
  type        = string
  default     = "192.168.0.0/16"
}

# DEFINE EL TIPO DE INSTANCIA EC2 UTILIZADO POR LOS SERVIDORES K3S.
variable "tipo_instancia" {
  description = "Tipo de instancia EC2 de  servidores K3s."
  type        = string
  default     = "t3.medium"
}

# DEFINE LA VERSIÓN DE K3S QUE SE INSTALARÁ EN LOS SERVIDORES.
variable "version_k3s" {
  description = "Version de K3s a instalar. Vacio instala la ultima disponible."
  type        = string
  default     = "v1.37.2+k3s1"
}

# DEFINE  EL PERÍODO DE CONSERVACIÓN DE LOS REGISTROS EN CLOUDWATCH.
variable "dias_retencion_logs" {
  description = "Dias de retencion de logs en CloudWatch."
  type        = number
  default     = 14
}

# DEFINE SI SE HABILITA LA RECUPERACIÓN AUTOMÁTICA DE LAS INSTANCIAS EC2.
variable "habilitar_recuperacion_ec2" {
  description = "Alarma que recupera automaticamente una instancia ante fallo."
  type        = bool
  default     = false
}

# DEFINE EL NOMBRE DEL BUCKET S3 PARA LOS RESPALDOS.
variable "nombre_bucket" {
  description = "Nombre del bucket S3 para los snapshots."
  type        = string
}
