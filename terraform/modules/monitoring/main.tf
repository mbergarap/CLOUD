
# REGISTROS CLOUDWATCH

# Log group donde los nodos K3s envian los logs de los pods (CloudWatch Agent).
resource "aws_cloudwatch_log_group" "k3s" {
  name              = var.nombre_grupo_logs
  retention_in_days = var.dias_retencion_logs

  tags = {
    Name = "${var.nombre_proyecto}-logs-k3s"
  }
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

# ALARMA CPU WORKERS

# CPU promedio del grupo de workers (los nodos cambian con el autoescalado).
resource "aws_cloudwatch_metric_alarm" "workers_cpu_high" {
  alarm_name        = "${var.nombre_proyecto}-workers-cpu-high"
  alarm_description = "CPU promedio de los workers superior al 80%"

  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  period              = 300

  metric_name = "CPUUtilization"
  namespace   = "AWS/EC2"
  statistic   = "Average"
  threshold   = 80

  dimensions = {
    AutoScalingGroupName = var.nombre_asg_workers
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  treat_missing_data = "notBreaching"
}

# ALARMA ERRORES 5XX

# Detecta errores del frontend vistos por el ALB.
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name        = "${var.nombre_proyecto}-alb-5xx"
  alarm_description = "Mas de 10 errores 5xx por minuto durante 3 minutos"

  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  period              = 60

  metric_name = "HTTPCode_Target_5XX_Count"
  namespace   = "AWS/ApplicationELB"
  statistic   = "Sum"
  threshold   = 10

  dimensions = {
    LoadBalancer = var.sufijo_arn_alb
  }

  alarm_actions = [aws_sns_topic.alerts.arn]

  treat_missing_data = "notBreaching"
}

# ALARMA NODOS NO SALUDABLES

# Avisa cuando algun nodo del Target Group falla el health check.
resource "aws_cloudwatch_metric_alarm" "alb_unhealthy" {
  alarm_name        = "${var.nombre_proyecto}-alb-unhealthy-hosts"
  alarm_description = "Hay nodos K3s no saludables en el Target Group"

  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  period              = 60

  metric_name = "UnHealthyHostCount"
  namespace   = "AWS/ApplicationELB"
  statistic   = "Maximum"
  threshold   = 1

  dimensions = {
    LoadBalancer = var.sufijo_arn_alb
    TargetGroup  = var.sufijo_arn_destino
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  treat_missing_data = "notBreaching"
}

# DASHBOARD

# Vista unica con trafico, latencia, nodos, base de datos y errores en logs.
resource "aws_cloudwatch_dashboard" "principal" {
  dashboard_name = "${var.nombre_proyecto}-resumen"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric", x = 0, y = 0, width = 12, height = 6
        properties = {
          title  = "ALB: solicitudes y errores 5xx"
          region = var.region_aws
          stat   = "Sum"
          period = 60
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.sufijo_arn_alb],
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", var.sufijo_arn_alb]
          ]
        }
      },
      {
        type = "metric", x = 12, y = 0, width = 12, height = 6
        properties = {
          title   = "ALB: latencia p95"
          region  = var.region_aws
          stat    = "p95"
          period  = 60
          metrics = [["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.sufijo_arn_alb]]
        }
      },
      {
        type = "metric", x = 0, y = 6, width = 12, height = 6
        properties = {
          title  = "Workers K3s: nodos en servicio y CPU"
          region = var.region_aws
          stat   = "Average"
          period = 60
          metrics = [
            ["AWS/AutoScaling", "GroupInServiceInstances", "AutoScalingGroupName", var.nombre_asg_workers],
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", var.nombre_asg_workers]
          ]
        }
      },
      {
        type = "metric", x = 12, y = 6, width = 12, height = 6
        properties = {
          title  = "RDS: CPU y conexiones"
          region = var.region_aws
          stat   = "Average"
          period = 60
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.identificador_instancia_bd],
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", var.identificador_instancia_bd]
          ]
        }
      },
      {
        type = "log", x = 0, y = 12, width = 24, height = 6
        properties = {
          title  = "Logs de pods: ultimos errores"
          region = var.region_aws
          query  = "SOURCE '${aws_cloudwatch_log_group.k3s.name}' | fields @timestamp, @message | filter @message like /(?i)error/ | sort @timestamp desc | limit 50"
        }
      }
    ]
  })
}
