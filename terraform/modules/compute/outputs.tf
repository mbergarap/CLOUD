# INSTANCIAS KUBERNETES
output "instance_ids" {
  value = concat([aws_instance.primary.id], aws_instance.secondary[*].id)
}
# BALANCEADOR
output "alb_dns" {
  value = aws_lb.alb.dns_name
}
output "alb_arn_suffix" {
  value = aws_lb.alb.arn_suffix
}
output "target_group_suffix" {
  value = aws_lb_target_group.web.arn_suffix
}
