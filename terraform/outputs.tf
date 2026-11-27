# MUESTRA LA DIRECCION WEB DE ONLINE BOUTIQUE.
output "url_online_boutique" {
  description = "URL publica de Online Boutique."
  value       = "http://${module.compute.alb_dns}"

  depends_on = [
    aws_ssm_association.verificar_kubernetes
  ]
}

# MUESTRA LOS IDENTIFICADORES DE LAS INSTANCIAS EC2 DEL CLÚSTER K3S.
output "instancias_k3s" {
  description = "Identificadores de las tres instancias EC2."
  value       = module.compute.instance_ids
}

# MUESTRA EL IDENTIFICADOR DEL SISTEMA DE ARCHIVOS.
output "efs_id" {
  description = "Identificador del sistema de archivos."
  value       = module.storage.efs_id
}

# MUESTRA EL NOMBRE DEL GRUPO DE LOGS DE CLOUDWATCH.
output "grupo_logs" {
  description = "Grupo de CloudWatch Logs con los logs de los nodos y los pods."
  value       = module.logging.log_group_name
}

# MUESTRA EL NOMBRE DEL DASHBOARD DE CLOUDWATCH.
output "dashboard_cloudwatch" {
  description = "Nombre del dashboard de CloudWatch."
  value       = module.monitoring.nombre_dashboard
}
