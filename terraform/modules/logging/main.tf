# LOGS CENTRALIZADOS EN CLOUDWATCH
# No se crean buckets S3 con Terraform: AWS Academy bloquea consultas de Object Lock.
resource "aws_cloudwatch_log_group" "k3s" {
  name              = "/${var.nombre_proyecto}/k3s"
  retention_in_days = var.dias_retencion
}
