# =========================
# SECURITY GROUP - ALB
# =========================

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-sg-alb"
  description = "Security Group del Application Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP desde Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Salida permitida"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg-alb"
  }
}

# =========================
# SECURITY GROUP - BASTION
# =========================

resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-sg-bastion"
  description = "Security Group del Bastion Host"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH temporal desde Internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Salida permitida"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg-bastion"
  }
}

# =========================
# SECURITY GROUP - APP
# =========================

resource "aws_security_group" "app" {
  name        = "${var.project_name}-sg-app"
  description = "Security Group de las EC2 de aplicacion"
  vpc_id      = var.vpc_id

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

  egress {
    description = "Salida permitida"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg-app"
  }
}

# =========================
# SECURITY GROUP - RDS
# =========================

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-sg-rds"
  description = "Security Group de RDS PostgreSQL"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL solo desde EC2 App"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    description = "Salida permitida"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg-rds"
  }
}