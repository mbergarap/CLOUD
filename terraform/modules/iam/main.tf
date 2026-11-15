
# ROL IAM PARA EC2

# Rol que permite a las instancias EC2 utilizar los permisos definidos.
resource "aws_iam_role" "ec2_role" {
  name = "${var.nombre_proyecto}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.nombre_proyecto}-ec2-role"
  }
}

# ACCESO A S3

# Permite descargar solamente app.zip del bucket de la aplicacion.
resource "aws_iam_role_policy" "s3_access" {
  name = "${var.nombre_proyecto}-s3-access"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "s3:GetObject"
        ]

        Resource = [
          "arn:aws:s3:::${var.nombre_bucket_aplicacion}/app.zip"
        ]
      }
    ]
  })
}

# CLOUDWATCH LOGS

# Permite enviar y consultar los registros de la aplicacion.
resource "aws_iam_role_policy" "cloudwatch_logs" {
  name = "${var.nombre_proyecto}-cloudwatch-logs"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]

        Resource = [
          "arn:aws:logs:*:*:log-group:/${var.nombre_proyecto}/*"
        ]
      }
    ]
  })
}

# SECRETS MANAGER

# Permite obtener el secreto de RDS cuando usamos IAM propio.
# No condicionamos este recurso al ARN porque RDS lo genera durante el despliegue.
resource "aws_iam_role_policy" "secrets_manager" {
  name = "${var.nombre_proyecto}-secrets-manager"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "secretsmanager:GetSecretValue"
        ]

        Resource = [
          var.arn_secreto_bd
        ]
      }
    ]
  })
}

# PERFIL IAM PARA EC2

# Asocia el rol IAM con las instancias mediante un Instance Profile.
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.nombre_proyecto}-instance-profile"
  role = aws_iam_role.ec2_role.name

  tags = {
    Name = "${var.nombre_proyecto}-instance-profile"
  }
}
