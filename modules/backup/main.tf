resource "aws_backup_vault" "this" {
  name = "${var.name}-vault"
  tags = var.tags
}

resource "aws_backup_plan" "daily" {
  name = "${var.name}-daily"

  rule {
    rule_name         = "daily-${var.retention_days}d"
    target_vault_name = aws_backup_vault.this.name
    schedule          = var.schedule

    lifecycle {
      delete_after = var.retention_days
    }
  }
  tags = var.tags
}

resource "aws_backup_selection" "this" {
  name         = "${var.name}-selection"
  plan_id      = aws_backup_plan.daily.id
  iam_role_arn = var.iam_role_arn
  resources    = var.resource_arns
}
