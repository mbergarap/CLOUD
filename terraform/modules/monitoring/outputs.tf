output "nginx_access_log_group" {
  value = aws_cloudwatch_log_group.nginx_access.name
}

output "nginx_error_log_group" {
  value = aws_cloudwatch_log_group.nginx_error.name
}

output "app_access_log_group" {
  value = aws_cloudwatch_log_group.app_access.name
}

output "app_error_log_group" {
  value = aws_cloudwatch_log_group.app_error.name
}