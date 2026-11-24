# Módulo `logging`

> Documentación generada a partir de `variables.tf`, `outputs.tf` y `main.tf`.

## Recursos

- `aws_cloudwatch_log_group.k3s`

## Variables

| Nombre | Tipo | Descripción | Valor por defecto |
|---|---|---|---|
| `nombre_proyecto` | `string` |  | obligatoria |
| `dias_retencion` | `number` |  | obligatoria |

## Salidas

| Nombre | Descripción |
|---|---|
| `log_group_name` | "Nombre del grupo CloudWatch Logs para K3s." |
