
# BALANCEADOR DE CARGA

# Recibe las conexiones HTTP y distribuye el trafico entre las instancias APP.
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

# TARGET GROUP

# Agrupa las instancias de aplicacion que reciben el trafico del ALB.
resource "aws_lb_target_group" "app" {
  name     = "${var.nombre_proyecto}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.id_vpc

  # Comprueba que la aplicacion responda correctamente.
  health_check {
    enabled             = true
    path                = "/health"
    protocol            = "HTTP"
    port                = "traffic-port"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Name = "${var.nombre_proyecto}-tg"
  }
}

# LISTENER HTTP

# Escucha en el puerto 80 y envia las solicitudes al Target Group.
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn

  port     = 80
  protocol = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
