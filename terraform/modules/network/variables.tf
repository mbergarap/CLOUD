variable "project_name" {
  description = "Prefijo comun para los recursos"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR de la VPC"
  type        = string
}

variable "az1" {
  description = "Availability Zone 1"
  type        = string
}

variable "az2" {
  description = "Availability Zone 2"
  type        = string
}

variable "public_subnet_az1_cidr" {
  type = string
}

variable "public_subnet_az2_cidr" {
  type = string
}

variable "app_subnet_az1_cidr" {
  type = string
}

variable "app_subnet_az2_cidr" {
  type = string
}

variable "db_subnet_az1_cidr" {
  type = string
}

variable "db_subnet_az2_cidr" {
  type = string
}