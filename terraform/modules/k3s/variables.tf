
# CONFIGURACION GENERAL

# Nombre utilizado para identificar los recursos del cluster.
variable "nombre_proyecto" {
  description = "Nombre del proyecto."
  type        = string
}

# RED Y SEGURIDAD

# VPC donde se encuentran los nodos Kubernetes.
variable "id_vpc" {
  description = "ID de la VPC."
  type        = string
}

# Subredes privadas donde se distribuyen los nodos.
variable "id_subred_app_az1" {
  description = "ID de la subred de aplicacion de AZ1."
  type        = string
}

variable "id_subred_app_az2" {
  description = "ID de la subred de aplicacion de AZ2."
  type        = string
}

# Security Group del Bastion utilizado para el acceso SSH.
variable "id_sg_bastion" {
  description = "ID del Security Group del Bastion."
  type        = string
}

# Security Group del ALB utilizado para acceder a Online Boutique.
variable "id_sg_alb" {
  description = "ID del Security Group del ALB."
  type        = string
}

# ACCESO SSH

# Clave utilizada para conectarnos a los nodos.
variable "nombre_clave_ssh" {
  description = "Nombre de la clave SSH registrada en AWS."
  type        = string
}

# INSTANCIAS K3S

# Tipo de EC2 utilizado para el servidor principal.
variable "tipo_instancia_servidor" {
  description = "Tipo de instancia EC2 del servidor K3s."
  type        = string
  default     = "t3.medium"
}

# Tipo de EC2 utilizado para los workers.
variable "tipo_instancia_worker" {
  description = "Tipo de instancia EC2 de los workers K3s."
  type        = string
  default     = "t3.small"
}

# IAM

# Perfil IAM utilizado por las instancias del cluster.
variable "nombre_perfil_instancia" {
  description = "Nombre del Instance Profile utilizado por K3s."
  type        = string
}


# AUTOESCALADO DE WORKERS

variable "nombre_asg_workers" {
  description = "Nombre del Auto Scaling Group de workers."
  type        = string
}

variable "workers_minimo" {
  description = "Cantidad minima de workers."
  type        = number
  default     = 2
}

variable "workers_deseado" {
  description = "Cantidad inicial de workers."
  type        = number
  default     = 2
}

variable "workers_maximo" {
  description = "Cantidad maxima de workers."
  type        = number
  default     = 4
}

variable "cpu_objetivo_workers" {
  description = "CPU promedio objetivo (%) para escalar los nodos."
  type        = number
  default     = 60
}

variable "arn_grupo_destino" {
  description = "ARN del Target Group del ALB donde se registran los workers."
  type        = string
}

# DESPLIEGUE DE LA APLICACION

variable "repo_manifiestos" {
  description = "URL https del repositorio Git con los manifiestos."
  type        = string
}

variable "rama_manifiestos" {
  description = "Rama del repositorio que se despliega."
  type        = string
  default     = "main"
}

variable "ruta_manifiestos" {
  description = "Carpeta del repositorio con los manifiestos."
  type        = string
  default     = "kubernetes"
}

variable "direccion_bd" {
  description = "Direccion de RDS (se publica en el ConfigMap infra-endpoints)."
  type        = string
}

variable "usuario_bd" {
  description = "Usuario de PostgreSQL."
  type        = string
  sensitive   = true
}

variable "arn_secreto_bd" {
  description = "ARN del secreto administrado por RDS."
  type        = string
}

variable "endpoint_redis" {
  description = "Endpoint primario de ElastiCache Redis."
  type        = string
}

variable "nombre_grupo_logs" {
  description = "Log group de CloudWatch donde se envian los logs de los nodos."
  type        = string
}

# SALIDA DEL FIREWALL

# CIDRs de las subredes de base de datos (destino permitido para RDS y Redis).
variable "cidrs_subredes_bd" {
  description = "CIDRs de las subredes de base de datos."
  type        = list(string)
}
