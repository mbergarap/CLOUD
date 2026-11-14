
# =========================
# NETWORK
# =========================

module "network" {
  source = "./modules/network"

  project_name = var.project_name

  vpc_cidr = "192.168.0.0/16"

  az1 = "us-east-1a"
  az2 = "us-east-1b"

  public_subnet_az1_cidr = "192.168.1.0/24"
  public_subnet_az2_cidr = "192.168.2.0/24"

  app_subnet_az1_cidr = "192.168.10.0/24"
  app_subnet_az2_cidr = "192.168.20.0/24"

  db_subnet_az1_cidr = "192.168.30.0/24"
  db_subnet_az2_cidr = "192.168.40.0/24"
}

# =========================
# SECURITY GROUPS
# =========================

module "security" {
  source = "./modules/security"

  project_name = var.project_name
  vpc_id       = module.network.vpc_id
}

# =========================
# BASTION
# =========================

module "bastion" {
  source = "./modules/bastion"

  project_name = var.project_name

  public_subnet_id = module.network.public_subnet_az1_id
  bastion_sg_id    = module.security.bastion_sg_id

  public_key_path = var.ssh_public_key_path
  ami_id          = var.bastion_ami_id
}

# =========================
# APPLICATION LOAD BALANCER
# =========================

module "alb" {
  source = "./modules/alb"

  project_name = var.project_name
  vpc_id       = module.network.vpc_id

  public_subnet_az1_id = module.network.public_subnet_az1_id
  public_subnet_az2_id = module.network.public_subnet_az2_id

  alb_sg_id = module.security.alb_sg_id
}

# =========================
# S3 APLICACION
# =========================

module "s3" {
  source = "./modules/s3"

  project_name = var.project_name
  bucket_name  = var.app_bucket_name

  app_source_dir = "${path.root}/../app"
  app_zip_path   = "${path.root}/app.zip"
}

# =========================
# IAM - PERFIL OPCIONAL PARA EC2
# =========================

module "iam" {
  source = "./modules/iam"

  # false = reutilizar perfil existente (AWS Academy)
  # true  = crear rol y perfil IAM (AWS estandar)
  count = var.create_iam_profile ? 1 : 0

  project_name    = var.project_name
  app_bucket_name = var.app_bucket_name
}

# =========================
# DATABASE
# =========================

module "database" {
  source = "./modules/database"

  project_name = var.project_name

  db_subnet_az1_id = module.network.db_subnet_az1_id
  db_subnet_az2_id = module.network.db_subnet_az2_id

  rds_sg_id = module.security.rds_sg_id

  db_username = var.db_username
  db_password = var.db_password

  deletion_protection = var.rds_deletion_protection
}

# =========================
# MONITORING
# =========================

module "monitoring" {
  source = "./modules/monitoring"

  project_name = var.project_name
  alert_email  = var.alert_email

  # Nombre conocido para evitar dependencia circular
  # entre compute y monitoring.
  asg_name = "${var.project_name}-asg"

  db_instance_identifier = module.database.db_instance_identifier
}

# =========================
# COMPUTE / AUTO SCALING
# =========================

module "compute" {
  source = "./modules/compute"

  project_name = var.project_name

  app_subnet_az1_id = module.network.app_subnet_az1_id
  app_subnet_az2_id = module.network.app_subnet_az2_id

  app_sg_id = module.security.app_sg_id

  key_name = module.bastion.key_name

  target_group_arn = module.alb.target_group_arn

  app_bucket_name = module.s3.bucket_name

  db_host     = module.database.db_address
  db_name     = module.database.db_name
  db_user     = var.db_username
  db_password = var.db_password

  nginx_access_log_group = module.monitoring.nginx_access_log_group
  nginx_error_log_group  = module.monitoring.nginx_error_log_group

  app_access_log_group = module.monitoring.app_access_log_group
  app_error_log_group  = module.monitoring.app_error_log_group

  # AWS Academy: LabInstanceProfile.
  # AWS estandar: perfil creado por el modulo IAM.
  instance_profile_name = (
    var.create_iam_profile
    ? module.iam[0].instance_profile_name
    : var.ec2_instance_profile_name
  )

  # En el modo AWS estandar, esperar que las politicas
  # IAM esten creadas antes de lanzar las EC2.
  depends_on = [module.iam]
}
