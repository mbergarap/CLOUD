
output "nombre_boveda" {
  description = "Nombre de la boveda de AWS Backup."
  value       = aws_backup_vault.principal.name
}

output "id_plan" {
  description = "ID del plan de respaldos."
  value       = aws_backup_plan.diario.id
}
