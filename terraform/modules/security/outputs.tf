# BALANCEADOR
output "alb_sg_id" { value = aws_security_group.alb.id }
# KUBERNETES
output "k3s_sg_id" { value = aws_security_group.k3s.id }
# ALMACENAMIENTO EFS
output "efs_sg_id" { value = aws_security_group.efs.id }
