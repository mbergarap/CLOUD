# ALERTAS SNS
resource "aws_sns_topic" "alertas" {
  name = "isc-obligatorio-alertas"
}
resource "aws_sns_topic_subscription" "correo" {
  topic_arn = aws_sns_topic.alertas.arn
  protocol  = "email"
  endpoint  = var.alerta_mail
}

# CPU DE INSTANCIAS
resource "aws_cloudwatch_metric_alarm" "cpu" {
  count               = 3
  alarm_name          = "isc-obligatorio-cpu-${count.index + 1}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Uso de CPU elevado"
  dimensions = {
    InstanceId = var.instance_ids[count.index]
  }
  treat_missing_data = "missing"
  alarm_actions      = [aws_sns_topic.alertas.arn]
}

# SALUD DEL BALANCEADOR
resource "aws_cloudwatch_metric_alarm" "targets" {
  alarm_name          = "isc-obligatorio-targets-inactivos"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  treat_missing_data  = "missing"
  alarm_description   = "Targets del ALB sin salud"
  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.target_group_suffix
  }
  alarm_actions = [aws_sns_topic.alertas.arn]
}
