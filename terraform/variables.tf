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
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,19}$", var.nombre_proyecto))
    error_message = "El nombre del proyecto debe tener de 3 a 20 caracteres: minusculas, numeros y guiones, empezando con una letra."
  }
}

# DEFINE LA REGIÓN DE AWS PARA EL DESPLIEGUE.
variable "region" {
  description = "Region de AWS donde se despliega la infraestructura."
  type        = string
  default     = "us-east-1"
  validation {
    condition     = can(regex("^[a-z]{2}(-[a-z]+)+-[0-9]$", var.region))
    error_message = "Region invalida: usar un codigo como us-east-1."
  }
}

# DEFINE EL RANGO DE DIRECCIONES IP DE LA VPC.
variable "cidr_vpc" {
  description = "Bloque ip de la VPC. Las subredes se calculan a partir de este bloque."
  type        = string
  default     = "192.168.0.0/16"
  validation {
    condition     = can(cidrhost(var.cidr_vpc, 0)) && can(regex("^[0-9.]+/(1[6-9]|20)$", var.cidr_vpc))
    error_message = "El CIDR de la VPC debe ser valido y tener una mascara entre /16 y /20 (las subredes se calculan con /24 a /28)."
  }
}

# DEFINE EL TIPO DE INSTANCIA EC2 UTILIZADO POR LOS SERVIDORES K3S.
variable "tipo_instancia" {
  description = "Tipo de instancia EC2 de  servidores K3s."
  type        = string
  default     = "t3.medium"
  validation {
    condition     = can(regex("^[a-z][a-z0-9]*\\.[a-z0-9]+$", var.tipo_instancia))
    error_message = "Tipo de instancia invalido: usar un formato como t3.medium."
  }
}

# DEFINE LA VERSIÓN DE K3S QUE SE INSTALARÁ EN LOS SERVIDORES.
variable "version_k3s" {
  description = "Version de K3s a instalar. Vacio instala la ultima disponible."
  type        = string
  default     = "v1.37.2+k3s1"
  validation {
    condition     = var.version_k3s == "" || can(regex("^v[0-9]+\\.[0-9]+\\.[0-9]+\\+k3s[0-9]+$", var.version_k3s))
    error_message = "Version de K3s invalida: usar un formato como v1.37.2+k3s1 o dejar vacio."
  }
}

# DEFINE  EL PERÍODO DE CONSERVACIÓN DE LOS REGISTROS EN CLOUDWATCH.
variable "dias_retencion_logs" {
  description = "Dias de retencion de logs en CloudWatch."
  type        = number
  default     = 14
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.dias_retencion_logs)
    error_message = "CloudWatch solo admite estos dias de retencion: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288 o 3653."
  }
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
  validation {
    condition = (
      can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.nombre_bucket)) &&
      !can(regex("\\.\\.", var.nombre_bucket)) &&
      !can(regex("^[0-9]{1,3}(\\.[0-9]{1,3}){3}$", var.nombre_bucket))
    )
    error_message = "Nombre de bucket S3 no valido: 3 a 63 caracteres, minusculas, numeros, puntos y guiones, sin '..' y sin formato de IP."
  }
}
