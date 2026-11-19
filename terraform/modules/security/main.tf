
# BALANCEADOR DE CARGA

# Controla las conexiones que recibe y realiza el ALB.
resource "aws_security_group" "alb" {
  name        = "${var.nombre_proyecto}-sg-alb"
  description = "Security Group del Application Load Balancer"
  vpc_id      = var.id_vpc

  tags = {
    Name = "${var.nombre_proyecto}-sg-alb"
  }
}

# Recibe solicitudes HTTP desde Internet.
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP desde Internet"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

# BASTION

# Permite administrar las instancias privadas mediante SSH.
resource "aws_security_group" "bastion" {
  name        = "${var.nombre_proyecto}-sg-bastion"
  description = "Security Group del Bastion Host"
  vpc_id      = var.id_vpc

  ingress {
    description = "SSH administrativo IP autorizada"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.cidr_ssh_bastion]
  }

  tags = {
    Name = "${var.nombre_proyecto}-sg-bastion"
  }
}

# BASE DE DATOS

# Protege el acceso a PostgreSQL desde la red privada.
resource "aws_security_group" "rds" {
  name        = "${var.nombre_proyecto}-sg-rds"
  description = "Security Group de RDS PostgreSQL"
  vpc_id      = var.id_vpc

  # No permite conexiones entrantes mientras no existan clientes autorizados.
  ingress = []

  # No necesita iniciar conexiones hacia otros destinos.
  egress = []

  tags = {
    Name = "${var.nombre_proyecto}-sg-rds"
  }
}