# =========================
# OUTPUTS DEL MODULO IAM
# =========================

output "instance_profile_name" {
  description = "Nombre del Instance Profile creado para las EC2"
  value       = aws_iam_instance_profile.ec2_profile.name
}

output "role_name" {
  description = "Nombre del rol IAM creado"
  value       = aws_iam_role.ec2_role.name
}