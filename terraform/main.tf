
# CONFIGURA LA VPC, LAS SUBREDES Y EL ENRUTAMIENTO DE LA RED.
module "network" {
  source          = "./modules/network"
  nombre_proyecto = var.nombre_proyecto
  cidr_vpc        = var.cidr_vpc
}

# CONFIGURA LOS GRUPOS DE SEGURIDAD DE LA INFRAESTRUCTURA.
module "security" {
  source          = "./modules/security"
  nombre_proyecto = var.nombre_proyecto
  vpc_id          = module.network.vpc_id
  cidr_vpc        = var.cidr_vpc
}

# CONFIGURA EL ALMACENAMIENTO COMPARTIDO EFS Y LOS RESPALDOS DE ETCD EN S3.
module "storage" {
  source          = "./modules/storage"
  nombre_proyecto = var.nombre_proyecto
  private_subnets = module.network.private_subnets
  efs_sg_id       = module.security.efs_sg_id
  nombre_bucket   = var.nombre_bucket
}

# CENTRALIZA LOS REGISTROS DE LA INFRAESTRUCTURA PARA FACILITAR SU MONITOREO.
module "logging" {
  source          = "./modules/logging"
  nombre_proyecto = var.nombre_proyecto
  dias_retencion  = var.dias_retencion_logs
}

# DESPLIEGA LOS SERVIDORES K3S Y EL BALANCEADOR DE CARGA.
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

  # ENTREGA EL MANIFIESTO COMPRIMIDO DE ONLINE BOUTIQUE Y EL IDENTIFICADOR DE EFS.
  manifest_b64gzip = base64gzip(file("${path.module}/../kubernetes/app.yaml"))
  efs_id           = module.storage.efs_id

  # GARANTIZA QUE LA RED, EL ALMACENAMIENTO Y LOS LOGS ESTEN CONFIGURADOS ANTES DE CREAR K3S.
  depends_on = [
    module.network,
    module.storage,
    module.logging
  ]
}

# CONFIGURA LAS METRICAS, ALARMAS Y NOTIFICACIONES DE CLOUDWATCH Y SNS.
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

