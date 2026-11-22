
# ROL IAM

# En AWS Academy no se pueden crear roles: se reutiliza el rol del laboratorio.
data "aws_iam_role" "respaldos" {
  name = var.nombre_rol_iam
}

# BOVEDA DE RESPALDOS

# Contenedor cifrado donde AWS Backup guarda los puntos de recuperacion.
resource "aws_backup_vault" "principal" {
  name = "${var.nombre_proyecto}-boveda"

  tags = {
    Name = "${var.nombre_proyecto}-boveda"
  }
}

# PLAN DIARIO

# Respaldo diario con retencion configurable.
resource "aws_backup_plan" "diario" {
  name = "${var.nombre_proyecto}-plan-diario"

  rule {
    rule_name         = "diario-${var.dias_retencion}-dias"
    target_vault_name = aws_backup_vault.principal.name
    schedule          = var.programacion

    lifecycle {
      delete_after = var.dias_retencion
    }
  }
}

# RECURSOS RESPALDADOS

# Todo recurso con el tag Backup=true (ej: el servidor K3s).
resource "aws_backup_selection" "por_tag" {
  name         = "${var.nombre_proyecto}-por-tag"
  plan_id      = aws_backup_plan.diario.id
  iam_role_arn = data.aws_iam_role.respaldos.arn

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "Backup"
    value = "true"
  }
}

# Recursos indicados por ARN (ej: la instancia RDS).
resource "aws_backup_selection" "explicitos" {
  count = length(var.arns_recursos) > 0 ? 1 : 0

  name         = "${var.nombre_proyecto}-explicitos"
  plan_id      = aws_backup_plan.diario.id
  iam_role_arn = data.aws_iam_role.respaldos.arn
  resources    = var.arns_recursos
}
