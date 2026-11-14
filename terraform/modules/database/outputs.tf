
# =========================
# OUTPUTS DATABASE
# =========================

# AWS Academy utiliza academy[0].
# AWS estandar utiliza managed[0].

output "db_address" {
  description = "Direccion privada de RDS"
  value = (
    var.manage_master_user_password
    ? aws_db_instance.managed[0].address
    : aws_db_instance.academy[0].address
  )
}

output "db_name" {
  description = "Nombre de la base de datos"
  value = (
    var.manage_master_user_password
    ? aws_db_instance.managed[0].db_name
    : aws_db_instance.academy[0].db_name
  )
}

output "db_instance_identifier" {
  description = "Identificador de RDS para CloudWatch"
  value = (
    var.manage_master_user_password
    ? aws_db_instance.managed[0].identifier
    : aws_db_instance.academy[0].identifier
  )
}

output "db_secret_arn" {
  description = "ARN del secreto administrado por RDS"
  value = (
    var.manage_master_user_password
    ? aws_db_instance.managed[0].master_user_secret[0].secret_arn
    : null
  )
}
