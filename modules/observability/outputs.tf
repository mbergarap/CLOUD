output "alb_logs_bucket" {
  value = aws_s3_bucket.alb_logs.bucket
}

output "app_log_group" {
  value = aws_cloudwatch_log_group.app.name
}
