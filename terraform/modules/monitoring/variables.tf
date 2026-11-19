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