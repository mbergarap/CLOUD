variable "name" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "instance_type" {
  type = string
  default = "t3.medium"
}

variable "subnet_ids" {
  type = list(string)
}

variable "security_group_ids" {
  type = list(string)
}

variable "instance_profile_name" {
  type = string
}

variable "target_group_arns" {
  type = list(string)
  default = []
}

variable "min_size" {
  type = number
  default = 2
}

variable "max_size" {
  type = number
  default = 5
}

variable "desired_size" {
  type = number
  default = 2
}

variable "cpu_target" {
  type = number
  default = 60
}

variable "k3s_server_ip" {
  type = string
}

variable "token_ssm_parameter" {
  type = string
  default = "/cloud-obligatorio/k3s/token"
}

variable "k3s_version" {
  type = string
  default = ""
}

variable "aws_region" {
  type = string
  default = "us-east-1"
}

variable "tags" {
  type = map(string)
  default = {}
}
