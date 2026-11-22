# Cambios en tu modulo `db` (RDS)

```hcl
resource "aws_db_instance" "main" {
  # ... lo que ya tenes ...
  backup_retention_period   = 7   # backups automaticos + point-in-time recovery
  backup_window             = "03:00-04:00"
  copy_tags_to_snapshot     = true
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.nombre_proyecto}-final"
  deletion_protection       = var.proteccion_eliminacion_rds
  password                  = random_password.db.result
}

resource "random_password" "db" {
  length  = 24
  special = false
}

resource "aws_ssm_parameter" "db_password" {
  name  = "/${var.nombre_proyecto}/rds/password"
  type  = "SecureString"
  value = random_password.db.result
}
```
Agregar el provider `random` (hashicorp/random) en providers.tf.
La contrasena igual queda en el state: el bucket del backend debe ser privado y cifrado.
