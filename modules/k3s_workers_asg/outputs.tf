output "asg_name" {
  value = aws_autoscaling_group.workers.name
}

output "asg_arn" {
  value = aws_autoscaling_group.workers.arn
}
