
#  BALANCEADOR
resource "aws_security_group" "alb" {
  name_prefix = "${var.nombre_proyecto}-alb-"
  description = "HTTP publico al ALB"
  vpc_id      = var.vpc_id
  lifecycle { create_before_destroy = true }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP desde Internet"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

# El ALB solo puede hablar con los nodos K3s (referencia al SG, no a un CIDR).
resource "aws_vpc_security_group_egress_rule" "alb_a_k3s" {
  security_group_id            = aws_security_group.alb.id
  description                  = "NodePort hacia Kubernetes"
  ip_protocol                  = "tcp"
  from_port                    = 30080
  to_port                      = 30080
  referenced_security_group_id = aws_security_group.k3s.id
}

#  KUBERNETES
resource "aws_security_group" "k3s" {
  name_prefix = "${var.nombre_proyecto}-k3s-"
  description = "Servidores K3s privados"
  vpc_id      = var.vpc_id
  lifecycle { create_before_destroy = true }
}

resource "aws_vpc_security_group_ingress_rule" "k3s_desde_alb" {
  security_group_id            = aws_security_group.k3s.id
  description                  = "Aplicacion desde ALB"
  ip_protocol                  = "tcp"
  from_port                    = 30080
  to_port                      = 30080
  referenced_security_group_id = aws_security_group.alb.id
}

# Puertos internos del cluster: solo entre miembros del mismo Security Group.
locals {
  puertos_k3s = {
    api     = { protocolo = "tcp", inicio = 6443, fin = 6443 }
    etcd    = { protocolo = "tcp", inicio = 2379, fin = 2380 }
    kubelet = { protocolo = "tcp", inicio = 10250, fin = 10250 }
    flannel = { protocolo = "udp", inicio = 8472, fin = 8472 }
  }
}

resource "aws_vpc_security_group_ingress_rule" "k3s_interno" {
  for_each                     = local.puertos_k3s
  security_group_id            = aws_security_group.k3s.id
  description                  = "Trafico interno ${each.key}"
  ip_protocol                  = each.value.protocolo
  from_port                    = each.value.inicio
  to_port                      = each.value.fin
  referenced_security_group_id = aws_security_group.k3s.id
}

resource "aws_vpc_security_group_egress_rule" "k3s_interno" {
  for_each                     = local.puertos_k3s
  security_group_id            = aws_security_group.k3s.id
  description                  = "Salida interna ${each.key}"
  ip_protocol                  = each.value.protocolo
  from_port                    = each.value.inicio
  to_port                      = each.value.fin
  referenced_security_group_id = aws_security_group.k3s.id
}

resource "aws_vpc_security_group_egress_rule" "k3s_https" {
  security_group_id = aws_security_group.k3s.id
  description       = "HTTPS: imagenes, K3s, S3, SSM y CloudWatch"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "k3s_http" {
  security_group_id = aws_security_group.k3s.id
  description       = "HTTP: repositorios del sistema operativo"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "k3s_dns_udp" {
  security_group_id = aws_security_group.k3s.id
  description       = "DNS de la VPC (UDP)"
  ip_protocol       = "udp"
  from_port         = 53
  to_port           = 53
  cidr_ipv4         = var.cidr_vpc
}

resource "aws_vpc_security_group_egress_rule" "k3s_dns_tcp" {
  security_group_id = aws_security_group.k3s.id
  description       = "DNS de la VPC (TCP)"
  ip_protocol       = "tcp"
  from_port         = 53
  to_port           = 53
  cidr_ipv4         = var.cidr_vpc
}

resource "aws_vpc_security_group_egress_rule" "k3s_nfs" {
  security_group_id            = aws_security_group.k3s.id
  description                  = "NFS hacia EFS"
  ip_protocol                  = "tcp"
  from_port                    = 2049
  to_port                      = 2049
  referenced_security_group_id = aws_security_group.efs.id
}

#  EFS
resource "aws_security_group" "efs" {
  name_prefix = "${var.nombre_proyecto}-efs-"
  description = "NFS desde K3s"
  vpc_id      = var.vpc_id
  lifecycle { create_before_destroy = true }
}

resource "aws_vpc_security_group_ingress_rule" "efs_nfs" {
  security_group_id            = aws_security_group.efs.id
  description                  = "NFS desde nodos"
  ip_protocol                  = "tcp"
  from_port                    = 2049
  to_port                      = 2049
  referenced_security_group_id = aws_security_group.k3s.id
}

