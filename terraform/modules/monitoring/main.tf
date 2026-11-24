# ---------------------------------------------------------------- ALERTAS SNS
resource "aws_sns_topic" "alertas" {
  name = "${var.nombre_proyecto}-alertas"
}

resource "aws_sns_topic_subscription" "correo" {
  topic_arn = aws_sns_topic.alertas.arn
  protocol  = "email"
  endpoint  = var.alerta_mail
}

locals {
  dim_alb = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.target_group_suffix
  }
  acciones = [aws_sns_topic.alertas.arn]
}

# ---------------------------------------------------------------- INSTANCIAS
# CPU elevada
resource "aws_cloudwatch_metric_alarm" "cpu" {
  count               = 3
  alarm_name          = "${var.nombre_proyecto}-cpu-${count.index + 1}"
  alarm_description   = "Uso de CPU superior al 80 % durante 10 minutos"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  dimensions          = { InstanceId = var.instance_ids[count.index] }
  treat_missing_data  = "missing"
  alarm_actions       = local.acciones
}

# Memoria elevada (metrica publicada por el CloudWatch Agent)
resource "aws_cloudwatch_metric_alarm" "memoria" {
  count               = 3
  alarm_name          = "${var.nombre_proyecto}-memoria-${count.index + 1}"
  alarm_description   = "Memoria superior al 85 % durante 10 minutos"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = 300
  statistic           = "Average"
  threshold           = 85
  dimensions          = { InstanceId = var.instance_ids[count.index] }
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.acciones
}

# Disco casi lleno (metrica publicada por el CloudWatch Agent)
resource "aws_cloudwatch_metric_alarm" "disco" {
  count               = 3
  alarm_name          = "${var.nombre_proyecto}-disco-${count.index + 1}"
  alarm_description   = "Disco raiz superior al 85 %"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "disk_used_percent"
  namespace           = "CWAgent"
  period              = 300
  statistic           = "Average"
  threshold           = 85
  dimensions = {
    InstanceId = var.instance_ids[count.index]
    path       = "/"
    device     = "nvme0n1p1"
    fstype     = "xfs"
  }
  treat_missing_data = "notBreaching"
  alarm_actions      = local.acciones
}

# Fallo del sistema subyacente: avisa y recupera la instancia (misma EBS, misma IP).
resource "aws_cloudwatch_metric_alarm" "recuperacion" {
  count               = 3
  alarm_name          = "${var.nombre_proyecto}-recuperacion-${count.index + 1}"
  alarm_description   = "Fallo de hardware del host: recupera la instancia automaticamente"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed_System"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  dimensions          = { InstanceId = var.instance_ids[count.index] }
  treat_missing_data  = "missing"
  alarm_actions = var.habilitar_recuperacion_ec2 ? concat(
    ["arn:aws:automate:${var.region}:ec2:recover"], local.acciones
  ) : local.acciones
}

# ---------------------------------------------------------------- BALANCEADOR
# Destinos sin salud
resource "aws_cloudwatch_metric_alarm" "targets" {
  alarm_name          = "${var.nombre_proyecto}-targets-inactivos"
  alarm_description   = "Hay targets del ALB sin salud"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  dimensions          = local.dim_alb
  treat_missing_data  = "missing"
  alarm_actions       = local.acciones
}

# Menos de dos destinos sanos: se pierde la redundancia
resource "aws_cloudwatch_metric_alarm" "targets_sanos" {
  alarm_name          = "${var.nombre_proyecto}-targets-sanos-bajos"
  alarm_description   = "Menos de 2 targets sanos: sin redundancia"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Minimum"
  threshold           = 2
  dimensions          = local.dim_alb
  treat_missing_data  = "breaching"
  alarm_actions       = local.acciones
}

# Errores 5xx generados por la aplicacion
resource "aws_cloudwatch_metric_alarm" "errores_5xx_destino" {
  alarm_name          = "${var.nombre_proyecto}-5xx-aplicacion"
  alarm_description   = "Mas de 10 respuestas 5xx de la aplicacion en 5 minutos"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  dimensions          = local.dim_alb
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.acciones
}

# Errores 5xx generados por el propio ALB (por ejemplo, sin destinos)
resource "aws_cloudwatch_metric_alarm" "errores_5xx_alb" {
  alarm_name          = "${var.nombre_proyecto}-5xx-balanceador"
  alarm_description   = "El ALB devuelve 5xx (502/503/504)"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  dimensions          = { LoadBalancer = var.alb_arn_suffix }
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.acciones
}

# Latencia
resource "aws_cloudwatch_metric_alarm" "latencia" {
  alarm_name          = "${var.nombre_proyecto}-latencia-p95"
  alarm_description   = "Percentil 95 del tiempo de respuesta superior a 2 segundos"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  extended_statistic  = "p95"
  threshold           = 2
  dimensions          = { LoadBalancer = var.alb_arn_suffix }
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.acciones
}

# ---------------------------------------------------------------- DASHBOARD
resource "aws_cloudwatch_dashboard" "principal" {
  dashboard_name = "${var.nombre_proyecto}-panel"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric", x = 0, y = 0, width = 12, height = 6
        properties = {
          title  = "ALB: solicitudes y errores 5xx"
          region = var.region
          stat   = "Sum"
          period = 60
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix],
            [".", "HTTPCode_Target_5XX_Count", ".", "."],
            [".", "HTTPCode_ELB_5XX_Count", ".", "."]
          ]
        }
      },
      {
        type = "metric", x = 12, y = 0, width = 12, height = 6
        properties = {
          title  = "ALB: latencia (promedio y p95)"
          region = var.region
          period = 60
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix, { stat = "Average" }],
            ["...", { stat = "p95" }]
          ]
        }
      },
      {
        type = "metric", x = 0, y = 6, width = 12, height = 6
        properties = {
          title  = "ALB: targets sanos y no sanos"
          region = var.region
          period = 60
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", "LoadBalancer", var.alb_arn_suffix, "TargetGroup", var.target_group_suffix, { stat = "Minimum" }],
            [".", "UnHealthyHostCount", ".", ".", ".", ".", { stat = "Maximum" }]
          ]
        }
      },
      {
        type = "metric", x = 12, y = 6, width = 12, height = 6
        properties = {
          title   = "EC2: CPU por nodo K3s"
          region  = var.region
          stat    = "Average"
          period  = 60
          metrics = [for id in var.instance_ids : ["AWS/EC2", "CPUUtilization", "InstanceId", id]]
        }
      },
      {
        type = "metric", x = 0, y = 12, width = 12, height = 6
        properties = {
          title   = "EC2: memoria usada (%) por nodo"
          region  = var.region
          stat    = "Average"
          period  = 60
          metrics = [for id in var.instance_ids : ["CWAgent", "mem_used_percent", "InstanceId", id]]
        }
      },
      {
        type = "log", x = 12, y = 12, width = 12, height = 6
        properties = {
          title  = "Ultimos logs de los pods"
          region = var.region
          view   = "table"
          query  = "SOURCE '${var.log_group}' | fields @timestamp, @logStream, @message | sort @timestamp desc | limit 50"
        }
      }
    ]
  })
}
