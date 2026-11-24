# LOGS CENTRALIZADOS EN CLOUDWATCH

resource "aws_cloudwatch_log_group" "k3s" {
  name              = "/${var.nombre_proyecto}/k3s"
  retention_in_days = var.dias_retencion
}
