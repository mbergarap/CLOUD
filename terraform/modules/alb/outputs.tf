
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


# TARGET GROUP ONLINE BOUTIQUE

# ARN del Target Group utilizado por los nodos K3s.
output "arn_grupo_destino_k3s" {
  description = "ARN del Target Group de Online Boutique."
  value       = aws_lb_target_group.k3s.arn
}

# Nombre del Target Group de Online Boutique.
output "nombre_grupo_destino_k3s" {
  description = "Nombre del Target Group de Online Boutique."
  value       = aws_lb_target_group.k3s.name
}


# SUFIJOS PARA CLOUDWATCH

# Dimension LoadBalancer de las metricas del ALB.
output "sufijo_arn_alb" {
  description = "Sufijo del ARN del ALB (dimension de CloudWatch)."
  value       = aws_lb.main.arn_suffix
}

# Dimension TargetGroup de las metricas del ALB.
output "sufijo_arn_grupo_destino_k3s" {
  description = "Sufijo del ARN del Target Group (dimension de CloudWatch)."
  value       = aws_lb_target_group.k3s.arn_suffix
}
