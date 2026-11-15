
# REGISTROS CLOUDWATCH

# Guardamos los registros de acceso y errores de Nginx durante 7 dias.
resource "aws_cloudwatch_log_group" "nginx_access" {
  name              = "/${var.nombre_proyecto}/nginx/access"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "nginx_error" {
  name              = "/${var.nombre_proyecto}/nginx/error"
  retention_in_days = 7
}

# Registros de acceso y errores de la aplicacion.
resource "aws_cloudwatch_log_group" "app_access" {
  name              = "/${var.nombre_proyecto}/app/access"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "app_error" {
  name              = "/${var.nombre_proyecto}/app/error"
  retention_in_days = 7
}

# NOTIFICACIONES SNS

# Tema SNS utilizado para enviar las alertas.
resource "aws_sns_topic" "alerts" {
  name = "${var.nombre_proyecto}-alerts"
}

# Suscripcion al correo donde recibimos las notificaciones.
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.correo_alertas
}

# ALARMA CPU AUTO SCALING

# Envia una alerta si el promedio de CPU del ASG supera el 80%.
resource "aws_cloudwatch_metric_alarm" "asg_cpu_high" {
  alarm_name        = "${var.nombre_proyecto}-asg-cpu-high"
  alarm_description = "CPU promedio del Auto Scaling Group superior al 80%"

  comparison_operator = "GreaterThanThreshold"

  evaluation_periods = 1
  period             = 300

  metric_name = "CPUUtilization"
  namespace   = "AWS/EC2"
  statistic   = "Average"
  threshold   = 80

  dimensions = {
    AutoScalingGroupName = var.nombre_asg
  }

  alarm_actions = [
    aws_sns_topic.alerts.arn
  ]

  ok_actions = [
    aws_sns_topic.alerts.arn
  ]

  treat_missing_data = "notBreaching"
}

# ALARMA CPU RDS

# Envia una alerta cuando el uso de CPU de RDS supera el 80%.
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name        = "${var.nombre_proyecto}-rds-cpu-high"
  alarm_description = "CPU de RDS superior al 80%"

  comparison_operator = "GreaterThanThreshold"

  evaluation_periods = 1
  period             = 300

  metric_name = "CPUUtilization"
  namespace   = "AWS/RDS"
  statistic   = "Average"
  threshold   = 80

  dimensions = {
    DBInstanceIdentifier = var.identificador_instancia_bd
  }

  alarm_actions = [
    aws_sns_topic.alerts.arn
  ]

  ok_actions = [
    aws_sns_topic.alerts.arn
  ]

  treat_missing_data = "notBreaching"
}
