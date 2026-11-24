output "log_group_name" {
  description = "Nombre del grupo CloudWatch Logs para K3s."
  value       = aws_cloudwatch_log_group.k3s.name
}
