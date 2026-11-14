# =========================
# CLOUDWATCH LOG GROUPS
# =========================

resource "aws_cloudwatch_log_group" "nginx_access" {
  name              = "/${var.project_name}/nginx/access"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "nginx_error" {
  name              = "/${var.project_name}/nginx/error"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "app_access" {
  name              = "/${var.project_name}/app/access"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "app_error" {
  name              = "/${var.project_name}/app/error"
  retention_in_days = 7
}

# =========================
# SNS
# =========================

resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# =========================
# ALARMA CPU EC2 / ASG
# =========================

resource "aws_cloudwatch_metric_alarm" "asg_cpu_high" {
  alarm_name        = "${var.project_name}-asg-cpu-high"
  alarm_description = "CPU promedio del Auto Scaling Group superior al 80%"

  comparison_operator = "GreaterThanThreshold"

  evaluation_periods = 1
  period             = 300

  metric_name = "CPUUtilization"
  namespace   = "AWS/EC2"
  statistic   = "Average"
  threshold   = 80

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }

  alarm_actions = [
    aws_sns_topic.alerts.arn
  ]

  ok_actions = [
    aws_sns_topic.alerts.arn
  ]

  treat_missing_data = "notBreaching"
}

# =========================
# ALARMA CPU RDS
# =========================

resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name        = "${var.project_name}-rds-cpu-high"
  alarm_description = "CPU de RDS superior al 80%"

  comparison_operator = "GreaterThanThreshold"

  evaluation_periods = 1
  period             = 300

  metric_name = "CPUUtilization"
  namespace   = "AWS/RDS"
  statistic   = "Average"
  threshold   = 80

  dimensions = {
    DBInstanceIdentifier = var.db_instance_identifier
  }

  alarm_actions = [
    aws_sns_topic.alerts.arn
  ]

  ok_actions = [
    aws_sns_topic.alerts.arn
  ]

  treat_missing_data = "notBreaching"
}