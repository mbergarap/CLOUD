
# AMI AMAZON LINUX 2023

# Buscamos la imagen mas reciente de Amazon Linux 2023.
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# CREDENCIALES DE BASE DE DATOS

# Preparamos las credenciales segun el entorno utilizado.
locals {
  credenciales_bd_secrets = <<-SECRETS
    aws secretsmanager get-secret-value \
      --region us-east-1 \
      --secret-id '${coalesce(var.arn_secreto_bd, "secreto-no-configurado")}' \
      --query SecretString \
      --output text \
      | python3 -c 'import json,sys; p=json.load(sys.stdin)["password"]; print("DB_PASSWORD="+json.dumps(p))' \
      > /etc/cloud-app/db.env
  SECRETS

  credenciales_bd_academy = <<-ACADEMY
    cat > /etc/cloud-app/db.env <<'DBENV'
    DB_PASSWORD=${jsonencode(var.contrasena_bd)}
    DBENV
  ACADEMY

  configuracion_credenciales_bd = var.administrar_contrasena_maestra ? local.credenciales_bd_secrets : local.credenciales_bd_academy
}

# LAUNCH TEMPLATE

# Configuracion utilizada para crear las instancias de aplicacion.
resource "aws_launch_template" "app" {
  name_prefix   = "${var.nombre_proyecto}-app-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  key_name      = var.nombre_clave_ssh

  vpc_security_group_ids = [
    var.id_sg_app
  ]

  # Perfil IAM de AWS Academy o de una cuenta estandar.
  iam_instance_profile {
    name = var.nombre_perfil_instancia
  }

  # Script que prepara la aplicacion cada vez que inicia una EC2 nueva.
  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -euo pipefail

    # =========================
    # INSTALAR PAQUETES
    # =========================

    dnf update -y

    dnf install -y \
      nginx \
      python3 \
      python3-pip \
      unzip \
      awscli-2 \
      amazon-cloudwatch-agent

    # =========================
    # DIRECTORIO DE LA APP
    # =========================

    mkdir -p /opt/cloud-app
    cd /opt/cloud-app

    # =========================
    # DESCARGAR APP DESDE S3
    # =========================

    aws s3 cp \
      s3://${var.nombre_bucket_aplicacion}/app.zip \
      /tmp/app.zip

    unzip -o \
      /tmp/app.zip \
      -d /opt/cloud-app

    # =========================
    # DEPENDENCIAS PYTHON
    # =========================

    pip3 install -r /opt/cloud-app/requirements.txt

    # =========================
    # ARCHIVOS DE LOG APP
    # =========================

    touch /var/log/cloud-app-access.log
    touch /var/log/cloud-app-error.log

    # =========================
    # CONFIGURAR CREDENCIALES DB
    # =========================

    install -d -m 700 /etc/cloud-app

    ${local.configuracion_credenciales_bd}

    chmod 600 /etc/cloud-app/db.env

    # =========================
    # SERVICIO FLASK / GUNICORN
    # =========================

    cat > /etc/systemd/system/cloud-app.service <<'SERVICE'
    [Unit]
    Description=Cloud Obligatorio Flask App
    After=network.target

    [Service]
    WorkingDirectory=/opt/cloud-app

    Environment="DB_HOST=${var.servidor_bd}"
    Environment="DB_PORT=5432"
    Environment="DB_NAME=${var.nombre_bd}"
    Environment="DB_USER=${var.usuario_bd}"

    EnvironmentFile=/etc/cloud-app/db.env

    ExecStart=/usr/local/bin/gunicorn \
      --workers 2 \
      --bind 127.0.0.1:8000 \
      --access-logfile /var/log/cloud-app-access.log \
      --error-logfile /var/log/cloud-app-error.log \
      app:app

    Restart=always
    RestartSec=5

    [Install]
    WantedBy=multi-user.target
    SERVICE

    # =========================
    # CONFIGURAR NGINX
    # =========================

    cat > /etc/nginx/conf.d/cloud-app.conf <<'NGINX'
    server {
        listen 80;
        server_name _;

        location / {
            proxy_pass http://127.0.0.1:8000;

            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
    NGINX

    rm -f /etc/nginx/conf.d/default.conf

    # =========================
    # CLOUDWATCH AGENT
    # =========================

    cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'CWCONFIG'
    {
      "agent": {
        "run_as_user": "root"
      },
      "logs": {
        "logs_collected": {
          "files": {
            "collect_list": [
              {
                "file_path": "/var/log/nginx/access.log",
                "log_group_name": "${var.grupo_logs_acceso_nginx}",
                "log_stream_name": "{instance_id}"
              },
              {
                "file_path": "/var/log/nginx/error.log",
                "log_group_name": "${var.grupo_logs_error_nginx}",
                "log_stream_name": "{instance_id}"
              },
              {
                "file_path": "/var/log/cloud-app-access.log",
                "log_group_name": "${var.grupo_logs_acceso_app}",
                "log_stream_name": "{instance_id}"
              },
              {
                "file_path": "/var/log/cloud-app-error.log",
                "log_group_name": "${var.grupo_logs_error_app}",
                "log_stream_name": "{instance_id}"
              }
            ]
          }
        }
      }
    }
    CWCONFIG

    # =========================
    # LEVANTAR SERVICIOS
    # =========================

    systemctl daemon-reload

    systemctl enable cloud-app
    systemctl restart cloud-app

    systemctl enable nginx
    systemctl restart nginx

    # =========================
    # INICIAR CLOUDWATCH AGENT
    # =========================

    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
      -a fetch-config \
      -m ec2 \
      -s \
      -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

  EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.nombre_proyecto}-app"
    }
  }

  tags = {
    Name = "${var.nombre_proyecto}-launch-template"
  }
}

# AUTO SCALING GROUP

# Mantiene dos instancias activas y permite aumentar hasta cuatro.
resource "aws_autoscaling_group" "app" {
  name = "${var.nombre_proyecto}-asg"

  min_size         = 2
  desired_capacity = 2
  max_size         = 4

  vpc_zone_identifier = [
    var.id_subred_app_az1,
    var.id_subred_app_az2
  ]

  target_group_arns = [
    var.arn_grupo_destino
  ]

  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.app.id
    version = aws_launch_template.app.latest_version
  }

  tag {
    key                 = "Name"
    value               = "${var.nombre_proyecto}-app"
    propagate_at_launch = true
  }
}

# ESCALADO POR CPU

# Ajusta la cantidad de instancias para mantener la CPU cerca del 60%.
resource "aws_autoscaling_policy" "cpu_target" {
  name                   = "${var.nombre_proyecto}-cpu-60"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 60.0
  }
}
