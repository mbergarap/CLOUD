
# SUBREDES DE BASE DE DATOS

# Agrupa las dos subredes privadas donde funciona RDS.
resource "aws_db_subnet_group" "main" {
  name = "${var.nombre_proyecto}-db-subnet-group"

  subnet_ids = [
    var.id_subred_bd_az1,
    var.id_subred_bd_az2
  ]

  tags = {
    Name = "${var.nombre_proyecto}-db-subnet-group"
  }
}

# SNAPSHOT FINAL

# Genera un identificador para evitar repetir nombres de snapshots.
resource "random_id" "snapshot_suffix" {
  byte_length = 4

  keepers = {
    db_identifier = "${var.nombre_proyecto}-rds"
  }
}

# RDS EN AWS ACADEMY

# PostgreSQL con credenciales configuradas desde Terraform.
resource "aws_db_instance" "academy" {
  count = var.administrar_contrasena_maestra ? 0 : 1

  identifier = "${var.nombre_proyecto}-rds"

  engine         = "postgres"
  engine_version = "16"

  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = "cloudapp"
  username = var.usuario_bd
  password = var.contrasena_bd

  port = 5432

  multi_az            = true
  publicly_accessible = false

  db_subnet_group_name = aws_db_subnet_group.main.name

  vpc_security_group_ids = [
    var.id_sg_rds
  ]

  backup_retention_period = 7
  deletion_protection     = var.proteccion_eliminacion

  skip_final_snapshot = false

  final_snapshot_identifier = "${var.nombre_proyecto}-final-${random_id.snapshot_suffix.hex}"

  storage_encrypted = true

  tags = {
    Name = "${var.nombre_proyecto}-rds"
  }
}

# RDS EN AWS ESTANDAR

# Alternativa donde RDS administra la contrasena con Secrets Manager.
resource "aws_db_instance" "managed" {
  count = var.administrar_contrasena_maestra ? 1 : 0

  identifier = "${var.nombre_proyecto}-rds"

  engine         = "postgres"
  engine_version = "16"

  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = "cloudapp"
  username = var.usuario_bd

  # La contrasena se administra mediante Secrets Manager.
  manage_master_user_password = true

  port = 5432

  multi_az            = true
  publicly_accessible = false

  db_subnet_group_name = aws_db_subnet_group.main.name

  vpc_security_group_ids = [
    var.id_sg_rds
  ]

  backup_retention_period = 7
  deletion_protection     = var.proteccion_eliminacion

  skip_final_snapshot = false

  final_snapshot_identifier = "${var.nombre_proyecto}-final-${random_id.snapshot_suffix.hex}"

  storage_encrypted = true

  tags = {
    Name = "${var.nombre_proyecto}-rds"
  }
}
