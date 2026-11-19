
# BALANCEADOR DE CARGA

# Recibe las conexiones HTTP y distribuye el trafico entre los nodos K3s.
resource "aws_lb" "main" {
  name               = "${var.nombre_proyecto}-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    var.id_sg_alb
  ]

  subnets = [
    var.id_subred_publica_az1,
    var.id_subred_publica_az2
  ]

  tags = {
    Name = "${var.nombre_proyecto}-alb"
  }
}

# TARGET GROUP ONLINE BOUTIQUE

# Agrupa los nodos K3s que reciben el trafico de Online Boutique.
resource "aws_lb_target_group" "k3s" {
  name        = "${var.nombre_proyecto}-k3s-tg"
  port        = 30080
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.id_vpc

  # Comprueba que el frontend de Online Boutique responda correctamente.
  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    port                = "traffic-port"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Name = "${var.nombre_proyecto}-k3s-tg"
  }
}

# LISTENER HTTP

# Escucha en el puerto 80 y envia las solicitudes a Online Boutique.
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn

  port     = 80
  protocol = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k3s.arn
  }
}
