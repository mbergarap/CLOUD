
# NETWORK

# Red principal, dividida en subredes publicas y privadas en dos zonas.
module "network" {
  source = "./modules/network"

  nombre_proyecto = var.nombre_proyecto

  cidr_vpc = "192.168.0.0/16"

  zona_disponibilidad_1 = "us-east-1a"
  zona_disponibilidad_2 = "us-east-1b"

  cidr_subred_publica_az1 = "192.168.1.0/24"
  cidr_subred_publica_az2 = "192.168.2.0/24"

  cidr_subred_app_az1 = "192.168.10.0/24"
  cidr_subred_app_az2 = "192.168.20.0/24"

  cidr_subred_bd_az1 = "192.168.30.0/24"
  cidr_subred_bd_az2 = "192.168.40.0/24"
}

# SECURITY GROUPS

# Reglas de acceso para controlar la comunicacion entre los componentes.
module "security" {
  source = "./modules/security"

  nombre_proyecto  = var.nombre_proyecto
  id_vpc           = module.network.id_vpc
  cidr_ssh_bastion = var.cidr_ssh_bastion
}

# BASTION

# Servidor de acceso SSH para administrar las instancias privadas.
module "bastion" {
  source = "./modules/bastion"

  nombre_proyecto = var.nombre_proyecto

  id_subred_publica = module.network.id_subred_publica_az1
  id_sg_bastion     = module.security.id_sg_bastion

  ruta_clave_publica_ssh = var.ruta_clave_publica_ssh
  id_ami                 = var.id_ami_bastion
}

# BALANCEADOR DE CARGA

# Recibe las solicitudes HTTP y las distribuye entre las instancias APP.
module "alb" {
  source = "./modules/alb"

  nombre_proyecto = var.nombre_proyecto
  id_vpc          = module.network.id_vpc

  id_subred_publica_az1 = module.network.id_subred_publica_az1
  id_subred_publica_az2 = module.network.id_subred_publica_az2

  id_sg_alb = module.security.id_sg_alb
}

# S3 APLICACION

# Guarda el archivo ZIP utilizado para desplegar la aplicacion.
module "s3" {
  source = "./modules/s3"

  nombre_proyecto       = var.nombre_proyecto
  nombre_bucket         = var.nombre_bucket_aplicacion


  # En AWS Academy usamos el metodo compatible con el laboratorio.
  usar_s3_nativo = var.usar_s3_nativo

  region_aws = var.region_aws
}


# BASE DE DATOS

# PostgreSQL RDS en las subredes privadas de ambas zonas.
module "database" {
  source = "./modules/database"

  nombre_proyecto = var.nombre_proyecto

  id_subred_bd_az1 = module.network.id_subred_bd_az1
  id_subred_bd_az2 = module.network.id_subred_bd_az2

  id_sg_rds = module.security.id_sg_rds

  usuario_bd    = var.usuario_bd
  contrasena_bd = var.contrasena_bd

  # En AWS Academy utilizamos la contrasena configurada.
  # En una cuenta estandar podemos administrarla con Secrets Manager.
  administrar_contrasena_maestra = var.administrar_contrasena_maestra_rds

  proteccion_eliminacion = var.proteccion_eliminacion_rds
}

# MONITOREO

# Registros, metricas y alertas de la aplicacion y la base de datos.
module "monitoring" {
  source = "./modules/monitoring"

  nombre_proyecto = var.nombre_proyecto
  correo_alertas  = var.correo_alertas

  # Definimos el nombre del ASG para evitar una dependencia circular.

  identificador_instancia_bd = module.database.identificador_instancia_bd

  # Identificamos las instancias EC2 del cluster K3s.
  ids_instancias_k3s = var.habilitar_k3s ? concat(
    [module.k3s[0].id_instancia_servidor],
    module.k3s[0].ids_instancias_workers
  ) : []
}

# KUBERNETES K3S

# Cluster K3s opcional, con sus nodos dentro de las subredes privadas.
module "k3s" {
  source = "./modules/k3s"
  count  = var.habilitar_k3s ? 1 : 0

  nombre_proyecto = var.nombre_proyecto

  id_vpc            = module.network.id_vpc
  id_subred_app_az1 = module.network.id_subred_app_az1
  id_subred_app_az2 = module.network.id_subred_app_az2

  id_sg_bastion           = module.security.id_sg_bastion
  id_sg_alb               = module.security.id_sg_alb
  nombre_clave_ssh        = module.bastion.nombre_clave_ssh
  nombre_perfil_instancia = var.nombre_perfil_iam_k3s
}

# DESTINOS ONLINE BOUTIQUE

# Registra el servidor y los dos workers K3s en el Target Group del ALB.
resource "aws_lb_target_group_attachment" "k3s" {
  count = var.habilitar_k3s ? 3 : 0

  target_group_arn = module.alb.arn_grupo_destino_k3s

  target_id = (
    count.index == 0
    ? module.k3s[0].id_instancia_servidor
    : module.k3s[0].ids_instancias_workers[count.index - 1]
  )

  port = 30080
}

# SALIDAS DEL BASTION

# Permite que el Bastion se conecte a Internet por HTTPS.
resource "aws_vpc_security_group_egress_rule" "bastion_https" {
  security_group_id = module.security.id_sg_bastion

  description = "HTTPS hacia Internet"
  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
  cidr_ipv4   = "0.0.0.0/0"
}

# Permite acceder por SSH desde el Bastion a los nodos K3s.
resource "aws_vpc_security_group_egress_rule" "bastion_ssh_k3s" {
  count = var.habilitar_k3s ? 1 : 0

  security_group_id = module.security.id_sg_bastion

  description                  = "SSH hacia K3s"
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
  referenced_security_group_id = module.k3s[0].id_sg_k3s
}

# SALIDA DEL ALB HACIA K3S

# Permite que el ALB envie solicitudes HTTP a Online Boutique.
resource "aws_vpc_security_group_egress_rule" "alb_hacia_k3s" {
  count = var.habilitar_k3s ? 1 : 0

  security_group_id = module.security.id_sg_alb

  description                  = "HTTP hacia Online Boutique en K3s"
  ip_protocol                  = "tcp"
  from_port                    = 30080
  to_port                      = 30080
  referenced_security_group_id = module.k3s[0].id_sg_k3s
}
