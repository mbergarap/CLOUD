variable "project_name" {
  type = string
}

variable "db_subnet_az1_id" {
  type = string
}

variable "db_subnet_az2_id" {
  type = string
}

variable "rds_sg_id" {
  type = string
}

variable "db_username" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}
variable "deletion_protection" {
  description = "Habilita la proteccion contra eliminacion de RDS"
  type        = bool
  default     = true
}