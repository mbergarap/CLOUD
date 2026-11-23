# BALANCEADOR
resource "aws_security_group" "alb" {
  name_prefix = "isc-obligatorio-alb-"
  description = "HTTP publico al ALB"
  vpc_id      = var.vpc_id
  ingress {
    description = "HTTP desde Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "NodePort hacia Kubernetes"
    from_port   = 30080
    to_port     = 30080
    protocol    = "tcp"
    cidr_blocks = ["10.80.0.0/16"]
  }
  lifecycle { create_before_destroy = true }
}

# KUBERNETES
resource "aws_security_group" "k3s" {
  name_prefix = "isc-obligatorio-k3s-"
  description = "Servidores K3s privados"
  vpc_id      = var.vpc_id
  ingress {
    description     = "Aplicacion desde ALB"
    from_port       = 30080
    to_port         = 30080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  egress {
    description = "HTTPS y SSM"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "HTTP instalacion"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "DNS VPC UDP"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["10.80.0.0/16"]
  }
  egress {
    description = "DNS VPC TCP"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["10.80.0.0/16"]
  }
  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      ingress,
      egress
    ]
  }
}
# PUERTOS INTERNOS DEL CLUSTER
locals {
  puertos_k3s = {
    api     = { protocolo = "tcp", inicio = 6443, fin = 6443 }
    etcd    = { protocolo = "tcp", inicio = 2379, fin = 2380 }
    kubelet = { protocolo = "tcp", inicio = 10250, fin = 10250 }
    flannel = { protocolo = "udp", inicio = 8472, fin = 8472 }
  }
}
resource "aws_security_group_rule" "k3s_ingress_interno" {
  for_each                 = local.puertos_k3s
  type                     = "ingress"
  security_group_id        = aws_security_group.k3s.id
  source_security_group_id = aws_security_group.k3s.id
  protocol                 = each.value.protocolo
  from_port                = each.value.inicio
  to_port                  = each.value.fin
  description              = "Trafico interno ${each.key}"
}
resource "aws_security_group_rule" "k3s_egress_interno" {
  for_each                 = local.puertos_k3s
  type                     = "egress"
  security_group_id        = aws_security_group.k3s.id
  source_security_group_id = aws_security_group.k3s.id
  protocol                 = each.value.protocolo
  from_port                = each.value.inicio
  to_port                  = each.value.fin
  description              = "Salida interna ${each.key}"
}

# ALMACENAMIENTO EFS
resource "aws_security_group" "efs" {
  name_prefix = "isc-obligatorio-efs-"
  description = "NFS desde K3s"
  vpc_id      = var.vpc_id
  ingress {
    description     = "NFS desde nodos"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.k3s.id]
  }
  lifecycle { create_before_destroy = true }
}
resource "aws_security_group_rule" "k3s_nfs" {
  type                     = "egress"
  security_group_id        = aws_security_group.k3s.id
  source_security_group_id = aws_security_group.efs.id
  protocol                 = "tcp"
  from_port                = 2049
  to_port                  = 2049
  description              = "NFS hacia EFS"
}
