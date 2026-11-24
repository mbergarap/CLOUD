output "efs_id" {
  value = aws_efs_file_system.redis.id
}

output "etcd_bucket" {
  value = "isc-obligatorio-etcd-${data.aws_caller_identity.current.account_id}"
}