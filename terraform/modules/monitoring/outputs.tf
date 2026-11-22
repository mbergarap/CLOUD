# NOTIFICACIONES

# Tema SNS donde llegan las alertas.
output "arn_tema_alertas" {
  description = "ARN del tema SNS de alertas."
  value       = aws_sns_topic.alerts.arn
}

# DASHBOARD

output "nombre_dashboard" {
  description = "Nombre del dashboard de CloudWatch."
  value       = aws_cloudwatch_dashboard.principal.dashboard_name
}
