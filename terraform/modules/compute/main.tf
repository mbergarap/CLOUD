
# OBTIENE LA IMAGEN AMAZON LINUX 2023 PARA LOS SERVIDORES EC2.
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# GENERA UN TOKEN ALEATORIO PARA LA AUTENTICACIÓN DEL CLÚSTER K3S.
resource "random_password" "k3s_token" {
  length  = 40
  special = false
}

# CREA EL SERVIDOR PRINCIPAL DEL CLÚSTER K3S.
resource "aws_instance" "primary" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.tipo_instancia
  subnet_id                   = var.private_subnets[0]
  associate_public_ip_address = false
  vpc_security_group_ids      = [var.k3s_sg_id]
  iam_instance_profile        = "LabInstanceProfile"

  # ENTREGA AL SERVIDOR PRINCIPAL LOS DATOS NECESARIOS PARA INSTALAR K3S Y ONLINE BOUTIQUE.
  user_data = templatefile("${path.module}/primary.sh.tftpl", {
    token            = random_password.k3s_token.result
    etcd_bucket      = var.etcd_bucket
    region           = var.region
    k3s_version      = var.version_k3s
    log_group        = var.log_group
    manifest_b64gzip = var.manifest_b64gzip
    efs_id           = var.efs_id
  })

  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  root_block_device {
    volume_size = 40
    volume_type = "gp3"
    encrypted   = true
  }

  lifecycle {
    ignore_changes = [user_data]
  }

  tags = {
    Name = "${var.nombre_proyecto}-k3s-1"
  }
}

# CREA DOS SERVIDORES SECUNDARIOS PARA EL CLÚSTER K3S.
resource "aws_instance" "secondary" {
  count                       = 2
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.tipo_instancia
  subnet_id                   = var.private_subnets[count.index + 1]
  associate_public_ip_address = false
  vpc_security_group_ids      = [var.k3s_sg_id]
  iam_instance_profile        = "LabInstanceProfile"

  user_data = templatefile("${path.module}/secondary.sh.tftpl", {
    token       = random_password.k3s_token.result
    server_ip   = aws_instance.primary.private_ip
    etcd_bucket = var.etcd_bucket
    region      = var.region
    k3s_version = var.version_k3s
    log_group   = var.log_group
  })

  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  root_block_device {
    volume_size = 40
    volume_type = "gp3"
    encrypted   = true
  }

  lifecycle {
    ignore_changes = [user_data]
  }

  tags = {
    Name = "${var.nombre_proyecto}-k3s-${count.index + 2}"
  }
}

# CREA EL BALANCEADOR DE CARGA PÚBLICO DE ONLINE BOUTIQUE.
resource "aws_lb" "alb" {
  name               = "${var.nombre_proyecto}-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = var.public_subnets
  security_groups    = [var.alb_sg_id]
}

# CONFIGURA EL GRUPO DE DESTINOS DEL ALB PARA LOS SERVIDORES K3S.
resource "aws_lb_target_group" "web" {
  name        = "${var.nombre_proyecto}-web"
  port        = 30080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    path                = "/"
    matcher             = "200"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
  }
}

# ASOCIA EL SERVIDOR PRINCIPAL AL GRUPO DE DESTINOS DEL ALB.
resource "aws_lb_target_group_attachment" "primary" {
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.primary.id
  port             = 30080
}

# ASOCIA LOS DOS SERVIDORES SECUNDARIOS AL GRUPO DE DESTINOS DEL ALB.
resource "aws_lb_target_group_attachment" "secondary" {
  count            = 2
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.secondary[count.index].id
  port             = 30080
}

# CONFIGURA EL LISTENER HTTP DEL ALB PARA DISTRIBUIR LAS SOLICITUDES.
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}
