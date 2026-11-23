
# IMAGEN DEL SISTEMA OPERATIVO
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

resource "random_password" "k3s_token" {
  length  = 40
  special = false
}

# SERVIDORES KUBERNETES
resource "aws_instance" "primary" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.medium"
  subnet_id                   = var.private_subnets[0]
  associate_public_ip_address = false
  vpc_security_group_ids      = [var.k3s_sg_id]
  iam_instance_profile        = "LabInstanceProfile"

  user_data = templatefile("${path.module}/primary.sh.tftpl", {
    token = random_password.k3s_token.result
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
    Name = "isc-obligatorio-k3s-1"
  }
}

resource "aws_instance" "secondary" {
  count                       = 2
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.medium"
  subnet_id                   = var.private_subnets[count.index + 1]
  associate_public_ip_address = false
  vpc_security_group_ids      = [var.k3s_sg_id]
  iam_instance_profile        = "LabInstanceProfile"

  user_data = templatefile("${path.module}/secondary.sh.tftpl", {
    token     = random_password.k3s_token.result
    server_ip = aws_instance.primary.private_ip
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
    Name = "isc-obligatorio-k3s-${count.index + 2}"
  }
}

# BALANCEADOR
resource "aws_lb" "alb" {
  name               = "isc-obligatorio-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = var.public_subnets
  security_groups    = [var.alb_sg_id]
}

# GRUPO DE DESTINOS
resource "aws_lb_target_group" "web" {
  name        = "isc-obligatorio-web"
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

resource "aws_lb_target_group_attachment" "primary" {
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.primary.id
  port             = 30080
}

resource "aws_lb_target_group_attachment" "secondary" {
  count            = 2
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.secondary[count.index].id
  port             = 30080
}

# LISTENER HTTP
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}
