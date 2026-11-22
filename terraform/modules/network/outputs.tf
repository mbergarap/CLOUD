
# VPC

output "id_vpc" {
  description = "ID de la VPC."
  value       = aws_vpc.main.id
}

# SUBREDES PUBLICAS

output "id_subred_publica_az1" {
  description = "ID de la subred publica de AZ1."
  value       = aws_subnet.public_az1.id
}

output "id_subred_publica_az2" {
  description = "ID de la subred publica de AZ2."
  value       = aws_subnet.public_az2.id
}

# SUBREDES DE APLICACION

output "id_subred_app_az1" {
  description = "ID de la subred APP de AZ1."
  value       = aws_subnet.app_az1.id
}

output "id_subred_app_az2" {
  description = "ID de la subred APP de AZ2."
  value       = aws_subnet.app_az2.id
}

# SUBREDES DE BASE DE DATOS

output "id_subred_bd_az1" {
  description = "ID de la subred de base de datos de AZ1."
  value       = aws_subnet.db_az1.id
}

output "id_subred_bd_az2" {
  description = "ID de la subred de base de datos de AZ2."
  value       = aws_subnet.db_az2.id
}
