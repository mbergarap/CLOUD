# VPC
output "vpc_id" {
  value = aws_vpc.main.id
}
# SUBREDES PUBLICAS
output "public_subnets" {
  value = aws_subnet.public[*].id
}
# SUBREDES PRIVADAS
output "private_subnets" {
  value = aws_subnet.private[*].id
}
