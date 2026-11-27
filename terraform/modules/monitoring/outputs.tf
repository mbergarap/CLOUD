
# EXPONE EL ARN DEL TOPICO SNS UTILIZADO PARA ENVIAR LAS ALERTAS DE MONITOREO.
output "topico_alertas_arn" {
  description = "ARN del topico SNS de alertas."
  value       = aws_sns_topic.alertas.arn
}

# EXPONE EL NOMBRE DEL DASHBOARD DE CLOUDWATCH QUE CENTRALIZA LAS METRICAS Y LOGS.
output "nombre_dashboard" {
  description = "Nombre del dashboard de CloudWatch."
  value       = aws_cloudwatch_dashboard.principal.dashboard_name
}
