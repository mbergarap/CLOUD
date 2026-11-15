
# BALANCEADOR DE CARGA

# Identificador del Security Group del ALB.
output "id_sg_alb" {
  description = "ID del Security Group del balanceador de carga."
  value       = aws_security_group.alb.id
}

# BASTION

# Identificador del Security Group utilizado para administrar las EC2.
output "id_sg_bastion" {
  description = "ID del Security Group del Bastion."
  value       = aws_security_group.bastion.id
}

# APLICACION

# Identificador del Security Group de las instancias APP.
output "id_sg_app" {
  description = "ID del Security Group de la aplicacion."
  value       = aws_security_group.app.id
}

# BASE DE DATOS

# Identificador del Security Group de PostgreSQL RDS.
output "id_sg_rds" {
  description = "ID del Security Group de la base de datos."
  value       = aws_security_group.rds.id
}
