# RED
module "network" {
  source          = "./modules/network"
  nombre_proyecto = var.nombre_proyecto
  cidr_vpc        = var.cidr_vpc
}

# SEGURIDAD
module "security" {
  source          = "./modules/security"
  nombre_proyecto = var.nombre_proyecto
  vpc_id          = module.network.vpc_id
  cidr_vpc        = var.cidr_vpc
}

# ALMACENAMIENTO
module "storage" {
  source          = "./modules/storage"
  nombre_proyecto = var.nombre_proyecto
  private_subnets = module.network.private_subnets
  efs_sg_id       = module.security.efs_sg_id
}

# LOGS CENTRALIZADOS
module "logging" {
  source          = "./modules/logging"
  nombre_proyecto = var.nombre_proyecto
  dias_retencion  = var.dias_retencion_logs
}

# COMPUTO
module "compute" {
  source          = "./modules/compute"
  nombre_proyecto = var.nombre_proyecto
  region          = var.region
  tipo_instancia  = var.tipo_instancia
  version_k3s     = var.version_k3s
  public_subnets  = module.network.public_subnets
  private_subnets = module.network.private_subnets
  k3s_sg_id       = module.security.k3s_sg_id
  alb_sg_id       = module.security.alb_sg_id
  vpc_id          = module.network.vpc_id
  etcd_bucket     = module.storage.etcd_bucket
  log_group       = module.logging.log_group_name

  # La ruta NAT, EFS y los logs deben existir antes de arrancar los servidores.
  depends_on = [module.network, module.storage, module.logging]
}

# MONITOREO
module "monitoring" {
  source                     = "./modules/monitoring"
  nombre_proyecto            = var.nombre_proyecto
  region                     = var.region
  alerta_mail                = var.alerta_mail
  alb_arn_suffix             = module.compute.alb_arn_suffix
  target_group_suffix        = module.compute.target_group_suffix
  instance_ids               = module.compute.instance_ids
  log_group                  = module.logging.log_group_name
  habilitar_recuperacion_ec2 = var.habilitar_recuperacion_ec2
}
