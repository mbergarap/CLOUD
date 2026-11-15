
# DATOS DE LA BASE DE DATOS

# En AWS Academy utilizamos academy[0].
# En AWS estandar utilizamos managed[0].

# Direccion privada para conectarse a PostgreSQL.
output "direccion_bd" {
  description = "Direccion de conexion a PostgreSQL RDS."
  value = (
    var.administrar_contrasena_maestra
    ? aws_db_instance.managed[0].address
    : aws_db_instance.academy[0].address
  )
}

# Nombre de la base de datos creada en RDS.
output "nombre_bd" {
  description = "Nombre de la base de datos PostgreSQL."
  value = (
    var.administrar_contrasena_maestra
    ? aws_db_instance.managed[0].db_name
    : aws_db_instance.academy[0].db_name
  )
}

# Identificador utilizado para monitorear RDS desde CloudWatch.
output "identificador_instancia_bd" {
  description = "Identificador de la instancia RDS."
  value = (
    var.administrar_contrasena_maestra
    ? aws_db_instance.managed[0].identifier
    : aws_db_instance.academy[0].identifier
  )
}

# ARN del secreto cuando RDS administra la contrasena.
output "arn_secreto_bd" {
  description = "ARN del secreto de PostgreSQL en Secrets Manager."
  value = (
    var.administrar_contrasena_maestra
    ? aws_db_instance.managed[0].master_user_secret[0].secret_arn
    : null
  )
}
