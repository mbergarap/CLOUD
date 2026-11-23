# RED
module "network" {
  source = "./modules/network"
}

# SEGURIDAD
module "security" {
  source = "./modules/security"
  vpc_id = module.network.vpc_id
}

# ALMACENAMIENTO
module "storage" {
  source          = "./modules/storage"
  private_subnets = module.network.private_subnets
  efs_sg_id       = module.security.efs_sg_id
}

# COMPUTO
module "compute" {
  source          = "./modules/compute"
  public_subnets  = module.network.public_subnets
  private_subnets = module.network.private_subnets
  k3s_sg_id       = module.security.k3s_sg_id
  alb_sg_id       = module.security.alb_sg_id
  vpc_id          = module.network.vpc_id
  # La ruta NAT y EFS deben existir antes de arrancar los servidores.
  depends_on = [module.network, module.storage]
}

# MONITOREO
module "monitoring" {
  source              = "./modules/monitoring"
  alerta_mail         = var.alerta_mail
  alb_arn_suffix      = module.compute.alb_arn_suffix
  target_group_suffix = module.compute.target_group_suffix
  instance_ids        = module.compute.instance_ids
}
