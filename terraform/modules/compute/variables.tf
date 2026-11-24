# SUBREDES PUBLICAS
variable "public_subnets" { type = list(string) }
# SUBREDES PRIVADAS
variable "private_subnets" { type = list(string) }
# SEGURIDAD KUBERNETES
variable "k3s_sg_id" { type = string }
# SEGURIDAD BALANCEADOR
variable "alb_sg_id" { type = string }
# VPC
variable "vpc_id" { type = string }
# BUCKET DE RESPALDOS ETCD
variable "etcd_bucket" {
  type = string
}