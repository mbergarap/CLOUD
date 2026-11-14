output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "bastion_id" {
  value = aws_instance.bastion.id
}

output "key_name" {
  value = aws_key_pair.bastion_key.key_name
}