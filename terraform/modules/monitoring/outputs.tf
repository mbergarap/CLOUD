# TOPICO SNS
output "topico_alertas_arn" {
  description = "ARN del topico SNS de alertas."
  value       = aws_sns_topic.alertas.arn
}

# DASHBOARD
output "nombre_dashboard" {
  description = "Nombre del dashboard de CloudWatch."
  value       = aws_cloudwatch_dashboard.principal.dashboard_name
}
