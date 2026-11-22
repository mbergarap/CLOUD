# SUBREDES DE ELASTICACHE

resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.nombre_proyecto}-redis-subnets"
  subnet_ids = [var.id_subred_bd_az1, var.id_subred_bd_az2]
}

# SECURITY GROUP REDIS

resource "aws_security_group" "redis" {
  name        = "${var.nombre_proyecto}-redis-sg"
  description = "Redis privado de Online Boutique"
  vpc_id      = var.id_vpc

  egress = []

  tags = {
    Name = "${var.nombre_proyecto}-redis-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "k3s_redis" {
  security_group_id            = aws_security_group.redis.id
  description                  = "Redis desde nodos K3s"
  referenced_security_group_id = var.id_sg_k3s
  ip_protocol                  = "tcp"
  from_port                    = 6379
  to_port                      = 6379
}

# REDIS MULTI-AZ

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "${var.nombre_proyecto}-redis"
  description          = "Almacenamiento del carrito Online Boutique"

  engine         = "redis"
  engine_version = "7.1"
  node_type      = "cache.t4g.micro"
  port           = 6379

  num_cache_clusters         = 2
  automatic_failover_enabled = true
  multi_az_enabled           = true

  preferred_cache_cluster_azs = [
    "us-east-1a",
    "us-east-1b"
  ]

  subnet_group_name  = aws_elasticache_subnet_group.redis.name
  security_group_ids = [aws_security_group.redis.id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  snapshot_retention_limit = 7
  apply_immediately        = false

  tags = {
    Name = "${var.nombre_proyecto}-redis"
  }
}