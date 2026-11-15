
# REGISTROS DE NGINX

# Grupo donde se guardan los accesos a Nginx.
output "grupo_logs_acceso_nginx" {
  description = "Nombre del grupo de registros de acceso de Nginx."
  value       = aws_cloudwatch_log_group.nginx_access.name
}

# Grupo donde se guardan los errores de Nginx.
output "grupo_logs_error_nginx" {
  description = "Nombre del grupo de registros de errores de Nginx."
  value       = aws_cloudwatch_log_group.nginx_error.name
}

# REGISTROS DE APLICACION

# Grupo utilizado para los accesos a la aplicacion.
output "grupo_logs_acceso_app" {
  description = "Nombre del grupo de registros de acceso de la aplicacion."
  value       = aws_cloudwatch_log_group.app_access.name
}

# Grupo utilizado para los errores de la aplicacion.
output "grupo_logs_error_app" {
  description = "Nombre del grupo de registros de errores de la aplicacion."
  value       = aws_cloudwatch_log_group.app_error.name
}
