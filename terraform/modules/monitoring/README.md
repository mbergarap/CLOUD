# Módulo `monitoring`

> Documentación generada a partir de `variables.tf`, `outputs.tf` y `main.tf`.

## Recursos

- `aws_sns_topic.alertas`
- `aws_sns_topic_subscription.correo`
- `aws_cloudwatch_metric_alarm.cpu`
- `aws_cloudwatch_metric_alarm.memoria`
- `aws_cloudwatch_metric_alarm.disco`
- `aws_cloudwatch_metric_alarm.recuperacion`
- `aws_cloudwatch_metric_alarm.targets`
- `aws_cloudwatch_metric_alarm.targets_sanos`
- `aws_cloudwatch_metric_alarm.errores_5xx_destino`
- `aws_cloudwatch_metric_alarm.errores_5xx_alb`
- `aws_cloudwatch_metric_alarm.latencia`
- `aws_cloudwatch_dashboard.principal`

## Variables

| Nombre | Tipo | Descripción | Valor por defecto |
|---|---|---|---|
| `nombre_proyecto` | `string` | "Prefijo usado en los nombres de los recursos." | obligatoria |
| `region` | `string` | "Region de AWS." | obligatoria |
| `alerta_mail` | `string` | "Correo electronico que recibira las alertas SNS." | obligatoria |
| `alb_arn_suffix` | `string` | "Sufijo del ARN del ALB (dimension LoadBalancer)." | obligatoria |
| `target_group_suffix` | `string` | "Sufijo del ARN del Target Group (dimension TargetGroup)." | obligatoria |
| `instance_ids` | `list(string)` | "Identificadores de las tres instancias K3s." | obligatoria |
| `log_group` | `string` | "Grupo de CloudWatch Logs de los nodos." | obligatoria |
| `habilitar_recuperacion_ec2` | `bool` | "Recupera la instancia automaticamente ante fallo del sistema (StatusCheckFailed_System)." | True |

## Salidas

| Nombre | Descripción |
|---|---|
| `topico_alertas_arn` | "ARN del topico SNS de alertas." |
| `nombre_dashboard` | "Nombre del dashboard de CloudWatch." |
