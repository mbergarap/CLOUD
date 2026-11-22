variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "alb_arn_suffix" {
  type = string
}

variable "target_group_suffix" {
  type = string
}

variable "rds_identifier" {
  type = string
}

variable "sns_topic_arn" {
  type = string
}

variable "flow_logs_role_arn" {
  type = string
}

variable "log_retention_days" {
  type = number
  default = 14
}

variable "rds_min_free_bytes" {
  type = number
  default = 2147483648
}

variable "tags" {
  type = map(string)
  default = {}
}
