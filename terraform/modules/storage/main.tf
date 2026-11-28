
# CREA EL SISTEMA DE ARCHIVOS EFS PARA EL ALMACENAMIENTO DE REDIS.
resource "aws_efs_file_system" "redis" {
  creation_token   = "${var.nombre_proyecto}-redis"
  encrypted        = true
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  tags             = { Name = "${var.nombre_proyecto}-redis" }
}

# CREA TRES PUNTOS DE MONTAJE DE EFS EN LAS SUBREDES PRIVADAS.
resource "aws_efs_mount_target" "redis" {
  count           = 3
  file_system_id  = aws_efs_file_system.redis.id
  subnet_id       = var.private_subnets[count.index]
  security_groups = [var.efs_sg_id]
}

# OBTIENE EL ROL IAM EXISTENTE DE AWS ACADEMY PARA LOS RESPALDOS.
data "aws_iam_role" "backup" {
  name = "LabRole"
}

# CREA EL ALMACÉN DE RESPALDOS DE AWS BACKUP.
resource "aws_backup_vault" "redis" {
  name = "${var.nombre_proyecto}-redis"

  # PERMITE BORRAR EL VAULT AUNQUE TENGA PUNTOS DE RECUPERACION (terraform destroy).
  force_destroy = true
}

# CONFIGURA LOS RESPALDOS DIARIOS DE EFS CON UNA RETENCIÓN DE SIETE DÍAS.
resource "aws_backup_plan" "redis" {
  name = "${var.nombre_proyecto}-redis"

  rule {
    rule_name         = "respaldo-diario"
    target_vault_name = aws_backup_vault.redis.name
    schedule          = "cron(0 3 * * ? *)"
    start_window      = 60
    completion_window = 180

    lifecycle {
      delete_after = 7
    }
  }
}

# ASOCIA EL SISTEMA DE ARCHIVOS EFS AL PLAN DE RESPALDOS.
resource "aws_backup_selection" "redis" {
  name         = "${var.nombre_proyecto}-redis"
  iam_role_arn = data.aws_iam_role.backup.arn
  plan_id      = aws_backup_plan.redis.id
  resources    = [aws_efs_file_system.redis.arn]
}

data "aws_caller_identity" "current" {}
