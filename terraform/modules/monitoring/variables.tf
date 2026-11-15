
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

# AUTO SCALING

# Nombre del grupo de instancias que vamos a monitorear.
variable "nombre_asg" {
  description = "Nombre del Auto Scaling Group."
  type        = string
}

# BASE DE DATOS

# Identificador de RDS utilizado en las alarmas de CloudWatch.
variable "identificador_instancia_bd" {
  description = "Identificador de la instancia PostgreSQL RDS."
  type        = string
}
