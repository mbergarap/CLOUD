
# =========================
# IAM ROLE PARA EC2
# =========================

resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"

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
    Name = "${var.project_name}-ec2-role"
  }
}

# =========================
# PERMISOS S3
# =========================

resource "aws_iam_role_policy" "s3_access" {
  name = "${var.project_name}-s3-access"
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
          "arn:aws:s3:::${var.app_bucket_name}/app.zip"
        ]
      }
    ]
  })
}

# =========================
# PERMISOS CLOUDWATCH LOGS
# =========================

resource "aws_iam_role_policy" "cloudwatch_logs" {
  name = "${var.project_name}-cloudwatch-logs"
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
          "arn:aws:logs:*:*:log-group:/${var.project_name}/*"
        ]
      }
    ]
  })
}

# =========================
# PERMISOS SECRETS MANAGER
# =========================

# Este modulo se utiliza en AWS estandar.
# No usamos count basado en el ARN, porque
# RDS genera ese valor durante terraform apply.

resource "aws_iam_role_policy" "secrets_manager" {
  name = "${var.project_name}-secrets-manager"
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
          var.db_secret_arn
        ]
      }
    ]
  })
}

# =========================
# INSTANCE PROFILE
# =========================

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-instance-profile"
  role = aws_iam_role.ec2_role.name

  tags = {
    Name = "${var.project_name}-instance-profile"
  }
}
