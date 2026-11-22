output "endpoint_redis" {
  description = "Endpoint primario de Redis"
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "puerto_redis" {
  value = aws_elasticache_replication_group.redis.port
}

output "id_sg_redis" {
  value = aws_security_group.redis.id
}