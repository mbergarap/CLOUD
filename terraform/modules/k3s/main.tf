
# AMI AMAZON LINUX 2023

# Utilizamos la misma imagen Amazon Linux 2023 de los nodos existentes.
data "aws_ssm_parameter" "ami_k3s" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# TOKEN DE K3S

# Generamos el token utilizado para unir los nodos al cluster.
# Su valor queda almacenado en el estado de Terraform.
resource "random_password" "join" {
  length  = 48
  special = false
}

# SECURITY GROUP K3S

# Controla las conexiones entre el servidor y los workers.
resource "aws_security_group" "k3s" {
  name        = "${var.nombre_proyecto}-k3s-sg"
  description = "Seguridad del cluster K3s"
  vpc_id      = var.id_vpc

  # SALIDA K3S
  # Mantiene la conectividad durante la migracion al ASG.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.nombre_proyecto}-k3s-sg"
  }
}

# ACCESO SSH

# Solo permitimos conexiones SSH desde el Bastion.
resource "aws_security_group_rule" "ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.k3s.id
  source_security_group_id = var.id_sg_bastion
}

# API DE KUBERNETES

# Permite la comunicacion interna con la API del cluster.
resource "aws_security_group_rule" "api" {
  type              = "ingress"
  from_port         = 6443
  to_port           = 6443
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.k3s.id
}

# KUBELET

# Habilita la comunicacion entre los nodos de Kubernetes.
resource "aws_security_group_rule" "kubelet" {
  type              = "ingress"
  from_port         = 10250
  to_port           = 10250
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.k3s.id
}

# RED DE PODS

# Flannel utiliza VXLAN para comunicar los pods entre nodos.
resource "aws_security_group_rule" "flannel" {
  type              = "ingress"
  from_port         = 8472
  to_port           = 8472
  protocol          = "udp"
  self              = true
  security_group_id = aws_security_group.k3s.id
}

# ACCESO ONLINE BOUTIQUE

# Permite recibir solicitudes HTTP desde el ALB.
resource "aws_security_group_rule" "frontend" {
  type                     = "ingress"
  from_port                = 30080
  to_port                  = 30080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.k3s.id
  source_security_group_id = var.id_sg_alb
}

# SERVIDOR K3S

# Nodo principal encargado del control del cluster.
resource "aws_instance" "server" {
  ami                    = data.aws_ssm_parameter.ami_k3s.value
  instance_type          = var.tipo_instancia_servidor
  subnet_id              = var.id_subred_app_az1
  vpc_security_group_ids = [aws_security_group.k3s.id]
  key_name               = var.nombre_clave_ssh

  iam_instance_profile = var.nombre_perfil_instancia

  user_data = templatefile("${path.module}/templates/server.sh.tftpl", {
    region           = data.aws_region.current.name
    parametro_token  = aws_ssm_parameter.join.name
    arn_secreto_bd   = var.arn_secreto_bd
    direccion_bd     = var.direccion_bd
    usuario_bd       = var.usuario_bd
    endpoint_redis   = var.endpoint_redis
    repo_manifiestos = var.repo_manifiestos
    rama_manifiestos = var.rama_manifiestos
    ruta_manifiestos = var.ruta_manifiestos
    grupo_logs       = var.nombre_grupo_logs
  })

  metadata_options {
    http_tokens = "required"
  }

  lifecycle {
    ignore_changes = [user_data]
  }

  tags = {
    Name = "${var.nombre_proyecto}-k3s-server"
  }
}

# WORKERS K3S (AUTO SCALING)

# Plantilla de lanzamiento de los workers. Cada instancia se une sola al cluster.
resource "aws_launch_template" "worker" {
  name_prefix   = "${var.nombre_proyecto}-k3s-worker-"
  image_id      = data.aws_ssm_parameter.ami_k3s.value
  instance_type = var.tipo_instancia_worker
  key_name      = var.nombre_clave_ssh

  iam_instance_profile {
    name = var.nombre_perfil_instancia
  }

  vpc_security_group_ids = [aws_security_group.k3s.id]

  metadata_options {
    http_tokens = "required"
  }

  user_data = base64encode(templatefile("${path.module}/templates/worker.sh.tftpl", {
    region          = data.aws_region.current.name
    parametro_token = aws_ssm_parameter.join.name
    ip_servidor     = aws_instance.server.private_ip
    grupo_logs      = var.nombre_grupo_logs
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.nombre_proyecto}-k3s-worker"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Grupo de autoescalado distribuido en las dos subredes de aplicacion (una por AZ).
# Se registra solo en el Target Group del ALB y se reemplaza si deja de estar sano.
resource "aws_autoscaling_group" "workers" {
  name = var.nombre_asg_workers

  min_size         = var.workers_minimo
  max_size         = var.workers_maximo
  desired_capacity = var.workers_deseado

  vpc_zone_identifier = [
    var.id_subred_app_az1,
    var.id_subred_app_az2
  ]

  target_group_arns         = [var.arn_grupo_destino]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.worker.id
    version = aws_launch_template.worker.latest_version
  }

  tag {
    key                 = "Name"
    value               = "${var.nombre_proyecto}-k3s-worker"
    propagate_at_launch = true
  }

  lifecycle {
    ignore_changes = [desired_capacity]
  }
}

# Escala la cantidad de NODOS segun CPU promedio (complementa el HPA de pods).
resource "aws_autoscaling_policy" "cpu" {
  name                   = "${var.nombre_proyecto}-workers-cpu"
  autoscaling_group_name = aws_autoscaling_group.workers.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.cpu_objetivo_workers
  }
}

# REGION AWS

# Obtenemos la region utilizada por los nodos.
data "aws_region" "current" {}

# PARAMETER STORE

# Guardamos el token de union de K3s como parametro cifrado.
resource "aws_ssm_parameter" "join" {
  name  = "/${var.nombre_proyecto}/k3s/join-token-${random_id.join_suffix.hex}"
  type  = "SecureString"
  value = random_password.join.result

  lifecycle {
    ignore_changes = [value]
  }
}

# IDENTIFICADOR UNICO DEL TOKEN K3S
resource "random_id" "join_suffix" {
  byte_length = 8
}
