# MUESTRA EL IDENTIFICADOR DEL GRUPO DE SEGURIDAD DEL ALB.
output "alb_sg_id" { value = aws_security_group.alb.id }
# MUESTRA EL IDENTIFICADOR DEL GRUPO DE SEGURIDAD DE K3S.
output "k3s_sg_id" { value = aws_security_group.k3s.id }
# MUESTRA EL IDENTIFICADOR DEL GRUPO DE SEGURIDAD DE EFS.
output "efs_sg_id" { value = aws_security_group.efs.id }
