# AUTO SCALING GROUP

# Nombre del grupo que administra las instancias de aplicacion.
output "nombre_grupo_autoescalado" {
  description = "Nombre del Auto Scaling Group de la aplicacion."
  value       = aws_autoscaling_group.app.name
}

# PLANTILLA DE LANZAMIENTO

# Identificador de la plantilla utilizada para crear las EC2.
output "id_plantilla_lanzamiento" {
  description = "ID del Launch Template utilizado por el ASG."
  value       = aws_launch_template.app.id
}
