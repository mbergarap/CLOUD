
# MUESTRA LOS IDENTIFICADORES DE LAS INSTANCIAS EC2 DEL CLÚSTER K3S.
output "instance_ids" {
  value = concat([aws_instance.primary.id], aws_instance.secondary[*].id)
}

# MUESTRA LA DIRECCIÓN DNS DEL BALANCEADOR DE CARGA.
output "alb_dns" {
  value = aws_lb.alb.dns_name
}

# MUESTRA EL SUFIJO ARN DEL BALANCEADOR DE CARGA PARA EL MONITOREO.
output "alb_arn_suffix" {
  value = aws_lb.alb.arn_suffix
}

# MUESTRA EL SUFIJO ARN DEL GRUPO DE DESTINOS PARA EL MONITOREO.
output "target_group_suffix" {
  value = aws_lb_target_group.web.arn_suffix
}
