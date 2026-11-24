# Módulo `compute`

> Documentación generada a partir de `variables.tf`, `outputs.tf` y `main.tf`.

## Recursos

- `random_password.k3s_token`
- `aws_instance.primary`
- `aws_instance.secondary`
- `aws_lb.alb`
- `aws_lb_target_group.web`
- `aws_lb_target_group_attachment.primary`
- `aws_lb_target_group_attachment.secondary`
- `aws_lb_listener.http`

## Variables

| Nombre | Tipo | Descripción | Valor por defecto |
|---|---|---|---|
| `nombre_proyecto` | `string` | "Prefijo usado en los nombres de los recursos." | obligatoria |
| `region` | `string` | "Region de AWS." | obligatoria |
| `tipo_instancia` | `string` | "Tipo de instancia EC2 de los servidores K3s." | obligatoria |
| `version_k3s` | `string` | "Version de K3s. Vacio instala la ultima disponible." | obligatoria |
| `public_subnets` | `list(string)` | "Subredes publicas del ALB." | obligatoria |
| `private_subnets` | `list(string)` | "Subredes privadas de los servidores K3s." | obligatoria |
| `k3s_sg_id` | `string` | "Security Group de los nodos K3s." | obligatoria |
| `alb_sg_id` | `string` | "Security Group del ALB." | obligatoria |
| `vpc_id` | `string` | "Identificador de la VPC." | obligatoria |
| `etcd_bucket` | `string` | "Bucket S3 de snapshots de etcd." | obligatoria |
| `log_group` | `string` | "Grupo de CloudWatch Logs donde el agente envia los logs." | obligatoria |

## Salidas

| Nombre | Descripción |
|---|---|
| `instance_ids` |  |
| `alb_dns` |  |
| `alb_arn_suffix` |  |
| `target_group_suffix` |  |
