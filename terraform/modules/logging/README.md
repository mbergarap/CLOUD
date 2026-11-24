# Modulo logging

Crea un grupo CloudWatch Logs para los logs de K3s y de los pods.
No administra buckets S3 de logs ALB por incompatibilidad con las politicas conocidas de AWS Academy.

Variables: `nombre_proyecto` y `dias_retencion`.

Salida: `log_group_name`.
