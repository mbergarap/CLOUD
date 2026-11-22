variable "name" {
  type = string
}

variable "resource_arns" {
  type = list(string)
}

variable "iam_role_arn" {
  type = string
}

variable "retention_days" {
  type = number
  default = 7
}

variable "schedule" {
  type = string
  default = "cron(0 5 * * ? *)"
}

variable "tags" {
  type = map(string)
  default = {}
}
