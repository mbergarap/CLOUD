
# BASTION

# Direccion IP publica para conectarnos por SSH.
output "ip_publica_bastion" {
  description = "IP publica del Bastion."
  value       = aws_instance.bastion.public_ip
}

# Identificador de la instancia EC2.
output "id_bastion" {
  description = "ID de la instancia Bastion."
  value       = aws_instance.bastion.id
}

# CLAVE SSH

# Nombre de la clave registrada en AWS.
output "nombre_clave_ssh" {
  description = "Nombre de la clave SSH utilizada por las instancias."
  value       = aws_key_pair.bastion_key.key_name
}
