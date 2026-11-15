
# CONFIGURACION GENERAL

# Nombre utilizado para identificar los recursos.
variable "nombre_proyecto" {
  description = "Nombre del proyecto."
  type        = string
}

# Nombre del bucket donde guardamos la aplicacion.
variable "nombre_bucket" {
  description = "Nombre unico del bucket S3 de la aplicacion."
  type        = string
}

# ARCHIVOS DE LA APLICACION

# Carpeta que contiene los archivos de la aplicacion.
variable "directorio_aplicacion" {
  description = "Directorio donde se encuentra la aplicacion."
  type        = string
}

# Ruta del archivo ZIP que se sube a S3.
variable "ruta_zip_aplicacion" {
  description = "Ruta donde se genera el archivo app.zip."
  type        = string
}

# CREACION DEL BUCKET

# En AWS Academy usamos AWS CLI; en otras cuentas podemos utilizar Terraform.
variable "usar_s3_nativo" {
  description = "True utiliza recursos Terraform; false utiliza AWS CLI."
  type        = bool
  default     = false
}

# REGION

# Region de AWS donde se encuentra el bucket.
variable "region_aws" {
  description = "Region de AWS utilizada para S3."
  type        = string
  default     = "us-east-1"
}
