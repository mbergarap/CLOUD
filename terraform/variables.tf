
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

variable "contrasena_bd" {
  description = "Contrasena de la base de datos."
  type        = string
  sensitive   = true
}

variable "administrar_contrasena_maestra_rds" {
  description = "Permite que RDS administre la contrasena mediante Secrets Manager."
  type        = bool
  default     = false
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

# PERMISOS IAM

variable "crear_perfil_iam" {
  description = "Indica si Terraform debe crear el perfil IAM."
  type        = bool
  default     = false
}

variable "nombre_perfil_iam_ec2" {
  description = "Nombre del perfil IAM utilizado por las instancias EC2."
  type        = string
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
