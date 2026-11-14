# =========================
# DB SUBNET GROUP
# =========================

resource "aws_db_subnet_group" "main" {
  name = "${var.project_name}-db-subnet-group"

  subnet_ids = [
    var.db_subnet_az1_id,
    var.db_subnet_az2_id
  ]

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# =========================
# SUFIJO UNICO SNAPSHOT
# =========================

resource "random_id" "snapshot_suffix" {
  byte_length = 4

  keepers = {
    db_identifier = "${var.project_name}-rds"
  }
}

# =========================
# RDS POSTGRESQL
# =========================

resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-rds"

  engine         = "postgres"
  engine_version = "16"

  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = "cloudapp"
  username = var.db_username
  password = var.db_password

  port = 5432

  multi_az            = true
  publicly_accessible = false

  db_subnet_group_name = aws_db_subnet_group.main.name

  vpc_security_group_ids = [
    var.rds_sg_id
  ]

  backup_retention_period = 7

  deletion_protection = var.deletion_protection

  skip_final_snapshot = false

  final_snapshot_identifier = "${var.project_name}-final-${random_id.snapshot_suffix.hex}"

  storage_encrypted = true

  tags = {
    Name = "${var.project_name}-rds"
  }
}