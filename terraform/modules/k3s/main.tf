
# AMI AMAZON LINUX 2023

# Utilizamos una imagen de Amazon Linux 2023 para los nodos.
data "aws_ami" "amazon_linux" {
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

# SERVIDOR K3S

# Nodo principal encargado del control del cluster.
resource "aws_instance" "server" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.tipo_instancia_servidor
  subnet_id              = var.id_subred_app_az1
  vpc_security_group_ids = [aws_security_group.k3s.id]
  key_name               = var.nombre_clave_ssh

  iam_instance_profile = var.nombre_perfil_instancia

  user_data = <<-USERDATA
    #!/bin/bash
    set -euo pipefail
    export AWS_DEFAULT_REGION="${data.aws_region.current.name}"

    TOKEN=""
    for attempt in $(seq 1 40); do
      TOKEN=$(aws ssm get-parameter --name "${aws_ssm_parameter.join.name}" --with-decryption --query 'Parameter.Value' --output text 2>/dev/null || true)
      if [ -n "$TOKEN" ] && [ "$TOKEN" != "None" ]; then
        break
      fi
      sleep 15
    done

    [ -n "$TOKEN" ] && [ "$TOKEN" != "None" ] || exit 1

    curl -sfL https://get.k3s.io | K3S_TOKEN="$TOKEN" INSTALL_K3S_EXEC='server --write-kubeconfig-mode 600 --disable traefik --disable servicelb' sh -
  USERDATA

  tags = {
    Name = "${var.nombre_proyecto}-k3s-server"
  }
}

# WORKERS K3S

# Creamos dos workers distribuidos entre las zonas de disponibilidad.
resource "aws_instance" "workers" {
  count = 2

  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.tipo_instancia_worker

  subnet_id = (
    count.index == 0
    ? var.id_subred_app_az1
    : var.id_subred_app_az2
  )

  vpc_security_group_ids = [aws_security_group.k3s.id]
  key_name               = var.nombre_clave_ssh

  iam_instance_profile = var.nombre_perfil_instancia

  user_data = <<-USERDATA
    #!/bin/bash
    set -euo pipefail
    export AWS_DEFAULT_REGION="${data.aws_region.current.name}"

    TOKEN=""
    for attempt in $(seq 1 40); do
      TOKEN=$(aws ssm get-parameter --name "${aws_ssm_parameter.join.name}" --with-decryption --query 'Parameter.Value' --output text 2>/dev/null || true)
      if [ -n "$TOKEN" ] && [ "$TOKEN" != "None" ]; then
        break
      fi
      sleep 15
    done

    [ -n "$TOKEN" ] && [ "$TOKEN" != "None" ] || exit 1

    for attempt in $(seq 1 60); do
      if curl -ksSf --connect-timeout 3 "https://${aws_instance.server.private_ip}:6443/ping" >/dev/null 2>&1; then
        break
      fi
      sleep 10
    done

    curl -sfL https://get.k3s.io | K3S_URL="https://${aws_instance.server.private_ip}:6443" K3S_TOKEN="$TOKEN" INSTALL_K3S_EXEC='agent' sh -
  USERDATA

  depends_on = [
    aws_instance.server
  ]

  tags = {
    Name = "${var.nombre_proyecto}-k3s-worker-${count.index + 1}"
  }
}

# REGION AWS

# Obtenemos la region utilizada por los nodos.
data "aws_region" "current" {}

# PARAMETER STORE

# Guardamos el token de union de K3s como parametro cifrado.
resource "aws_ssm_parameter" "join" {
  name  = "/${var.nombre_proyecto}/k3s/join-token"
  type  = "SecureString"
  value = random_password.join.result
}
