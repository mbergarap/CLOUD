# Monitoreo y logs

Código en `terraform/modules/monitoring` y `terraform/modules/logging`.

## Alarmas (17, notifican por SNS al correo configurado)

| Alarma | Condición |
|---|---|
| `…-cpu-{1..3}` | CPU > 80 % durante 10 min |
| `…-memoria-{1..3}` | Memoria > 85 % durante 10 min (CloudWatch Agent) |
| `…-disco-{1..3}` | Disco raíz > 85 % (CloudWatch Agent) |
| `…-recuperacion-{1..3}` | `StatusCheckFailed_System`: avisa por SNS; recupera la instancia (`ec2:recover`) solo si `habilitar_recuperacion_ec2 = true` (por defecto `false`) |
| `…-targets-inactivos` | Algún target del ALB sin salud |
| `…-targets-sanos-bajos` | Menos de 3 targets sanos (se perdio un nodo) |
| `…-5xx-aplicacion` | > 10 respuestas 5xx de la aplicación en 5 min |
| `…-5xx-balanceador` | > 5 respuestas 5xx generadas por el ALB en 5 min |
| `…-latencia-p95` | p95 del tiempo de respuesta > 2 s |

La suscripción SNS requiere **confirmar el correo** que envía AWS.

## Dashboard

`isc-obligatorio-panel` en CloudWatch: solicitudes y 5xx, latencia (promedio y p95), targets sanos/no sanos, CPU y memoria por nodo, y los últimos logs de los pods.

## Logs centralizados

| Origen | Destino | Retención |
|---|---|---|
| Logs de los pods (`/var/log/pods`) y de instalación de K3s | CloudWatch Logs, grupo `/isc-obligatorio/k3s` | `dias_retencion_logs` (14) |

El CloudWatch Agent se instala desde `user_data`. Es opcional: si falla, no impide levantar K3s. Para consultar: CloudWatch → Logs Insights → grupo `/isc-obligatorio/k3s`.

## Limitaciones

- Los logs de acceso del ALB **no están habilitados**: crear el bucket con Terraform fue rechazado por la política de AWS Academy (ver `COMPATIBILIDAD-AWS-ACADEMY.md`). El ALB se observa con sus métricas, alarmas y el dashboard.
- Los nodos ya creados no reciben el agente (el `user_data` solo corre al crear la instancia): hace falta un despliegue nuevo.
- Las métricas de memoria y disco dependen de que el agente funcione; si no, esas alarmas quedan en estado «sin datos» y no disparan.
