
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

# Nombre del Auto Scaling Group de workers.
output "nombre_asg_workers" {
  description = "Nombre del Auto Scaling Group de workers."
  value       = aws_autoscaling_group.workers.name
}

# SEGURIDAD K3S

# Security Group utilizado por los nodos del cluster.
output "id_sg_k3s" {
  description = "ID del Security Group de K3s."
  value       = aws_security_group.k3s.id
}
