# Módulo `network`

> Documentación generada a partir de `variables.tf`, `outputs.tf` y `main.tf`.

## Recursos

- `aws_vpc.main`
- `aws_internet_gateway.main`
- `aws_subnet.public`
- `aws_subnet.private`
- `aws_eip.nat`
- `aws_nat_gateway.nat`
- `aws_route_table.public`
- `aws_route_table_association.public`
- `aws_route_table.private`
- `aws_route_table_association.private`

## Variables

| Nombre | Tipo | Descripción | Valor por defecto |
|---|---|---|---|
| `nombre_proyecto` | `string` | "Prefijo usado en los nombres de los recursos." | obligatoria |
| `cidr_vpc` | `string` | "Bloque CIDR de la VPC." | obligatoria |

## Salidas

| Nombre | Descripción |
|---|---|
| `vpc_id` |  |
| `public_subnets` |  |
| `private_subnets` |  |
