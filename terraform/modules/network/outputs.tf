output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_az1_id" {
  value = aws_subnet.public_az1.id
}

output "public_subnet_az2_id" {
  value = aws_subnet.public_az2.id
}

output "app_subnet_az1_id" {
  value = aws_subnet.app_az1.id
}

output "app_subnet_az2_id" {
  value = aws_subnet.app_az2.id
}

output "db_subnet_az1_id" {
  value = aws_subnet.db_az1.id
}

output "db_subnet_az2_id" {
  value = aws_subnet.db_az2.id
}