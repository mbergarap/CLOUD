# DIRECCION DE ONLINE BOUTIQUE
output "url_online_boutique" {
  description = "URL publica de Online Boutique."
  value       = "http://${module.compute.alb_dns}"
}

# INSTANCIAS KUBERNETES
output "instancias_k3s" {
  description = "Identificadores de las tres instancias EC2."
  value       = module.compute.instance_ids
}

# ALMACENAMIENTO EFS
output "efs_id" {
  description = "Identificador del sistema de archivos EFS."
  value       = module.storage.efs_id
}

# LOGS
output "grupo_logs" {
  description = "Grupo de CloudWatch Logs con los logs de los nodos y los pods."
  value       = module.logging.log_group_name
}

# DASHBOARD
output "dashboard_cloudwatch" {
  description = "Nombre del dashboard de CloudWatch."
  value       = module.monitoring.nombre_dashboard
}
