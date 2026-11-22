
# CONFIGURACION GENERAL

variable "region_aws" {
  description = "Region donde se despliega la infraestructura."
  type        = string
  default     = "us-east-1"
}

variable "nombre_proyecto" {
  description = "Nombre utilizado para identificar los recursos."
  type        = string
  default     = "cloud-obligatorio"
}

# ACCESO SSH

variable "cidr_ssh_bastion" {
  description = "Rango de IP autorizado para acceder al bastion por SSH."
  type        = string
}

variable "ruta_clave_publica_ssh" {
  description = "Ruta de la clave publica SSH."
  type        = string
}

variable "id_ami_bastion" {
  description = "ID de la AMI utilizada por el bastion."
  type        = string
}

# BASE DE DATOS

variable "usuario_bd" {
  description = "Usuario administrador de la base de datos."
  type        = string
  default     = "cloudadmin"
  sensitive   = true
}


variable "administrar_contrasena_maestra_rds" {
  description = "RDS administra la contrasena con Secrets Manager."
  type        = bool
  default     = true
}

variable "proteccion_eliminacion_rds" {
  description = "Habilita la proteccion contra eliminacion de RDS."
  type        = bool
  default     = true
}

# ALMACENAMIENTO S3

variable "nombre_bucket_aplicacion" {
  description = "Nombre del bucket que almacena la aplicacion."
  type        = string
}

variable "usar_s3_nativo" {
  description = "Indica si Terraform administra el bucket mediante el proveedor AWS."
  type        = bool
  default     = false
}


# MONITOREO

variable "correo_alertas" {
  description = "Correo electronico para recibir alertas."
  type        = string
}

# KUBERNETES K3S

variable "habilitar_k3s" {
  description = "Indica si se despliega el cluster K3s."
  type        = bool
  default     = true
}

variable "nombre_perfil_iam_k3s" {
  description = "Nombre del perfil IAM utilizado por las instancias K3s."
  type        = string
}

variable "workers_minimo" {
  description = "Cantidad minima de workers K3s."
  type        = number
  default     = 2
}

variable "workers_deseado" {
  description = "Cantidad inicial de workers K3s."
  type        = number
  default     = 2
}

variable "workers_maximo" {
  description = "Cantidad maxima de workers K3s."
  type        = number
  default     = 4
}

variable "repo_manifiestos" {
  description = "URL https del repositorio Git con los manifiestos de Kubernetes."
  type        = string
  default     = "https://github.com/mbergarap/CLOUD.git"
}

variable "rama_manifiestos" {
  description = "Rama del repositorio desde la que se despliega la aplicacion."
  type        = string
  default     = "main"
}

# RESPALDOS

variable "habilitar_aws_backup" {
  description = "Crea la boveda y el plan diario de AWS Backup."
  type        = bool
  default     = false
}

variable "nombre_rol_aws_backup" {
  description = "Rol IAM de AWS Backup (AWS Academy: LabRole)."
  type        = string
  default     = "LabRole"
}

variable "dias_retencion_respaldos" {
  description = "Dias de retencion de los respaldos de AWS Backup."
  type        = number
  default     = 14
}
