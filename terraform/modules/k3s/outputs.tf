
# SERVIDOR K3S

# IP privada del nodo principal del cluster.
output "ip_privada_servidor" {
  description = "Direccion IP privada del servidor K3s."
  value       = aws_instance.server.private_ip
}

# ID de la instancia EC2 del servidor principal.
output "id_instancia_servidor" {
  description = "ID de la instancia EC2 del servidor K3s."
  value       = aws_instance.server.id
}

# WORKERS K3S

# Direcciones privadas de los dos workers.
output "ips_privadas_workers" {
  description = "Direcciones IP privadas de los workers K3s."
  value       = aws_instance.workers[*].private_ip
}

# IDs de las instancias EC2 de los workers.
output "ids_instancias_workers" {
  description = "IDs de las instancias EC2 de los workers K3s."
  value       = aws_instance.workers[*].id
}

# SEGURIDAD K3S

# Security Group utilizado por los nodos del cluster.
output "id_sg_k3s" {
  description = "ID del Security Group de K3s."
  value       = aws_security_group.k3s.id
}
