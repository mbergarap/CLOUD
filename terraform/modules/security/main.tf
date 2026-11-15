
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

# Envia solicitudes HTTP solamente a las instancias APP.
resource "aws_vpc_security_group_egress_rule" "alb_hacia_app" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.app.id
  description                  = "HTTP hacia EC2 de aplicacion"
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
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

# INSTANCIAS DE APLICACION

# Permite recibir HTTP desde el ALB y conexiones SSH desde el Bastion.
resource "aws_security_group" "app" {
  name        = "${var.nombre_proyecto}-sg-app"
  description = "Security Group de las EC2 de aplicacion"
  vpc_id      = var.id_vpc

  ingress {
    description     = "HTTP solo desde ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description     = "SSH solo desde Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  tags = {
    Name = "${var.nombre_proyecto}-sg-app"
  }
}

# SALIDAS DE APLICACION

# Conexion con la base de datos PostgreSQL.
resource "aws_vpc_security_group_egress_rule" "app_postgresql" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.rds.id
  description                  = "PostgreSQL hacia RDS"
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
}

# Acceso HTTPS para servicios AWS y dependencias.
resource "aws_vpc_security_group_egress_rule" "app_https" {
  security_group_id = aws_security_group.app.id
  description       = "HTTPS para servicios y dependencias"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

# Acceso HTTP para descargar paquetes durante el inicio.
resource "aws_vpc_security_group_egress_rule" "app_http" {
  security_group_id = aws_security_group.app.id
  description       = "HTTP para repositorios"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

# BASE DE DATOS

# Solo las instancias APP pueden conectarse a PostgreSQL.
resource "aws_security_group" "rds" {
  name        = "${var.nombre_proyecto}-sg-rds"
  description = "Security Group de RDS PostgreSQL"
  vpc_id      = var.id_vpc

  ingress {
    description     = "PostgreSQL solo desde EC2 App"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  # No necesita iniciar conexiones hacia otros destinos.
  egress = []

  tags = {
    Name = "${var.nombre_proyecto}-sg-rds"
  }
}
