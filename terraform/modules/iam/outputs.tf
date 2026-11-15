
# PERFIL IAM PARA EC2

# Nombre del perfil utilizado por las instancias EC2.
output "nombre_perfil_instancia" {
  description = "Nombre del Instance Profile creado para las EC2."
  value       = aws_iam_instance_profile.ec2_profile.name
}

# ROL IAM

# Nombre del rol que contiene los permisos de las instancias.
output "nombre_rol_iam" {
  description = "Nombre del rol IAM creado para las EC2."
  value       = aws_iam_role.ec2_role.name
}
