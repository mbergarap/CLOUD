
# REGISTROS CLOUDWATCH

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

# ALARMAS CPU K3S

# Supervisa el uso de CPU de cada instancia del cluster K3s.
resource "aws_cloudwatch_metric_alarm" "k3s_cpu_high" {
  count = length(var.ids_instancias_k3s)

  alarm_name        = "${var.nombre_proyecto}-k3s-cpu-high-${count.index + 1}"
  alarm_description = "CPU de la instancia K3s superior al 80%"

  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  period              = 300

  metric_name = "CPUUtilization"
  namespace   = "AWS/EC2"
  statistic   = "Average"
  threshold   = 80

  dimensions = {
    InstanceId = var.ids_instancias_k3s[count.index]
  }

  alarm_actions = [
    aws_sns_topic.alerts.arn
  ]

  ok_actions = [
    aws_sns_topic.alerts.arn
  ]

  treat_missing_data = "notBreaching"
}