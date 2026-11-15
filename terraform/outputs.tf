
# RED

output "id_vpc" {
  description = "ID de la VPC del proyecto."
  value       = module.network.id_vpc
}

# BASTION

output "ip_publica_bastion" {
  description = "IP publica del Bastion."
  value       = module.bastion.ip_publica_bastion
}

output "id_bastion" {
  description = "ID de la instancia Bastion."
  value       = module.bastion.id_bastion
}

# BALANCEADOR DE CARGA

output "nombre_dns_alb" {
  description = "Nombre DNS del balanceador."
  value       = module.alb.nombre_dns_alb
}

output "arn_alb" {
  description = "ARN del balanceador."
  value       = module.alb.arn_alb
}

# AUTO SCALING

output "nombre_grupo_autoescalado" {
  description = "Nombre del Auto Scaling Group."
  value       = module.compute.nombre_grupo_autoescalado
}

output "id_plantilla_lanzamiento" {
  description = "ID del Launch Template."
  value       = module.compute.id_plantilla_lanzamiento
}

# BASE DE DATOS

output "direccion_bd" {
  description = "Direccion de PostgreSQL RDS."
  value       = module.database.direccion_bd
}

output "nombre_bd" {
  description = "Nombre de la base de datos."
  value       = module.database.nombre_bd
}

output "identificador_instancia_bd" {
  description = "Identificador de RDS."
  value       = module.database.identificador_instancia_bd
}

# S3

output "nombre_bucket_aplicacion" {
  description = "Nombre del bucket S3 de la aplicacion."
  value       = module.s3.nombre_bucket
}

# KUBERNETES K3S

output "ip_privada_servidor_k3s" {
  description = "IP privada del servidor K3s."
  value       = var.habilitar_k3s ? module.k3s[0].ip_privada_servidor : null
}

output "ips_privadas_workers_k3s" {
  description = "IPs privadas de los workers."
  value       = var.habilitar_k3s ? module.k3s[0].ips_privadas_workers : []
}

output "id_sg_k3s" {
  description = "Security Group de K3s."
  value       = var.habilitar_k3s ? module.k3s[0].id_sg_k3s : null
}
