
# BALANCEADOR DE CARGA

# ARN del balanceador de carga.
output "arn_alb" {
  description = "ARN del balanceador de carga."
  value       = aws_lb.main.arn
}

# Direccion DNS que AWS asigna al ALB.
output "nombre_dns_alb" {
  description = "Nombre DNS publico del balanceador."
  value       = aws_lb.main.dns_name
}

# TARGET GROUP

# ARN del grupo de instancias que recibe el trafico.
output "arn_grupo_destino" {
  description = "ARN del Target Group de la aplicacion."
  value       = aws_lb_target_group.app.arn
}

# Nombre del Target Group creado en AWS.
output "nombre_grupo_destino" {
  description = "Nombre del Target Group de la aplicacion."
  value       = aws_lb_target_group.app.name
}
