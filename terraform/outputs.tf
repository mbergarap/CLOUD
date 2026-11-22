
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

output "nombre_asg_workers_k3s" {
  description = "Auto Scaling Group de los workers K3s."
  value       = var.habilitar_k3s ? module.k3s[0].nombre_asg_workers : null
}

output "id_sg_k3s" {
  description = "Security Group de K3s."
  value       = var.habilitar_k3s ? module.k3s[0].id_sg_k3s : null
}

# MONITOREO

output "nombre_dashboard" {
  description = "Dashboard de CloudWatch con el resumen de la solucion."
  value       = module.monitoring.nombre_dashboard
}

# RESPALDOS

output "boveda_respaldos" {
  description = "Boveda de AWS Backup (null si esta deshabilitado)."
  value       = var.habilitar_aws_backup ? module.respaldos[0].nombre_boveda : null
}
