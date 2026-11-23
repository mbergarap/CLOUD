# CORREO
variable "alerta_mail" { type = string }
# BALANCEADOR Y TARGET GROUP
variable "alb_arn_suffix" { type = string }
variable "target_group_suffix" { type = string }
# INSTANCIAS
variable "instance_ids" { type = list(string) }
