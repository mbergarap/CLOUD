# Módulo `security`

> Documentación generada a partir de `variables.tf`, `outputs.tf` y `main.tf`.

## Recursos

- `aws_security_group.alb`
- `aws_vpc_security_group_ingress_rule.alb_http`
- `aws_vpc_security_group_egress_rule.alb_a_k3s`
- `aws_security_group.k3s`
- `aws_vpc_security_group_ingress_rule.k3s_desde_alb`
- `aws_vpc_security_group_ingress_rule.k3s_interno`
- `aws_vpc_security_group_egress_rule.k3s_interno`
- `aws_vpc_security_group_egress_rule.k3s_https`
- `aws_vpc_security_group_egress_rule.k3s_http`
- `aws_vpc_security_group_egress_rule.k3s_dns_udp`
- `aws_vpc_security_group_egress_rule.k3s_dns_tcp`
- `aws_vpc_security_group_egress_rule.k3s_nfs`
- `aws_security_group.efs`
- `aws_vpc_security_group_ingress_rule.efs_nfs`

## Variables

| Nombre | Tipo | Descripción | Valor por defecto |
|---|---|---|---|
| `nombre_proyecto` | `string` | "Prefijo usado en los nombres de los recursos." | obligatoria |
| `vpc_id` | `string` | "Identificador de la VPC." | obligatoria |
| `cidr_vpc` | `string` | "Bloque CIDR de la VPC." | obligatoria |

## Salidas

| Nombre | Descripción |
|---|---|
| `alb_sg_id` |  |
| `k3s_sg_id` |  |
| `efs_sg_id` |  |
