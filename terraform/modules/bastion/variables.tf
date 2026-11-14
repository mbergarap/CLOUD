variable "project_name" {
  type = string
}

variable "public_subnet_id" {
  type = string
}

variable "bastion_sg_id" {
  type = string
}

variable "public_key_path" {
  type = string
}

variable "ami_id" {
  description = "AMI utilizada por la instancia bastion"
  type        = string
}