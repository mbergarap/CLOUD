
# DEFINE EL NOMBRE DEL PROYECTO PARA LOS RECURSOS DE CÓMPUTO.
variable "nombre_proyecto" {
  description = "Prefijo usado en los nombres de los recursos."
  type        = string
}

# DEFINE LA REGIÓN DE AWS PARA EL DESPLIEGUE.
variable "region" {
  description = "Region de AWS."
  type        = string
}

# DEFINE EL TIPO DE INSTANCIA EC2 UTILIZADO POR LOS SERVIDORES K3S.
variable "tipo_instancia" {
  description = "Tipo de instancia EC2 de los servidores K3s."
  type        = string
}

# ESTABLECE LA VERSIÓN DE K3S UTILIZADA PARA DESPLEGAR EL CLÚSTER KUBERNETES.
variable "version_k3s" {
  description = "Version de K3s. Vacio instala la ultima disponible."
  type        = string
}

# RECIBE LAS SUBREDES PÚBLICAS UTILIZADAS POR EL BALANCEADOR DE CARGA.
variable "public_subnets" {
  description = "Subredes publicas del ALB."
  type        = list(string)
}

# RECIBE LAS SUBREDES PRIVADAS UTILIZADAS POR LOS SERVIDORES K3S.
variable "private_subnets" {
  description = "Subredes privadas de los servidores K3s."
  type        = list(string)
}

# RECIBE EL IDENTIFICADOR DEL GRUPO DE SEGURIDAD DE K3S.
variable "k3s_sg_id" {
  description = "Security Group de los nodos K3s."
  type        = string
}

# RECIBE EL IDENTIFICADOR DEL GRUPO DE SEGURIDAD DEL ALB.
variable "alb_sg_id" {
  description = "Security Group del ALB."
  type        = string
}

# RECIBE EL IDENTIFICADOR DE LA VPC.
variable "vpc_id" {
  description = "Identificador de la VPC."
  type        = string
}

# DEFINE EL NOMBRE DEL BUCKET S3 PARA LOS RESPALDOS DE ETCD.
variable "etcd_bucket" {
  description = "Bucket S3 de snapshots de etcd."
  type        = string
}

# RECIBE EL NOMBRE DEL GRUPO DE LOGS DE CLOUDWATCH.
variable "log_group" {
  description = "Grupo de CloudWatch Logs donde el agente envia los logs."
  type        = string
}

# RECIBE EL MANIFIESTO COMPRIMIDO PARA DESPLEGAR ONLINE BOUTIQUE.
variable "manifest_b64gzip" {
  description = "Manifiesto Kubernetes comprimido y codificado en Base64."
  type        = string
}

# RECIBE EL IDENTIFICADOR DE EFS PARA CONFIGURAR EL ALMACENAMIENTO DE REDIS.
variable "efs_id" {
  description = "Identificador del sistema de archivos EFS."
  type        = string
}
