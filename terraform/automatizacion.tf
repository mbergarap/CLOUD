# Se crea mediante AWS CLI invocado por Terraform para evitar ese permiso denegado.
data "aws_caller_identity" "deploy" {}

locals {
  etcd_bucket = var.nombre_bucket
}

resource "terraform_data" "bucket_etcd" {
  triggers_replace = [local.etcd_bucket, var.region, filesha256("${path.module}/scripts/crear-bucket-etcd.ps1")]

  provisioner "local-exec" {
    interpreter = ["powershell.exe", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-Command"]
    command     = "& '${abspath(path.module)}/scripts/crear-bucket-etcd.ps1' -Region '${var.region}' -Bucket '${local.etcd_bucket}' -ExpectedAccount '${data.aws_caller_identity.deploy.account_id}'"
  }
}

# DESPLIEGUE Y VALIDACION KUBERNETES
# Terraform espera las instancias, EFS, alarmas y los permisos de red.
# Se ejecuta mediante SSM: no se necesita SSH ni kubectl local.
resource "terraform_data" "finalizar_kubernetes" {
  triggers_replace = [
    join(",", module.compute.instance_ids),
    module.storage.efs_id,
    filesha256("${path.module}/../kubernetes/app.yaml"),
    filesha256("${path.module}/scripts/finalizar-kubernetes.ps1"),
  ]

  depends_on = [module.compute, module.storage, module.monitoring, terraform_data.bucket_etcd]

  provisioner "local-exec" {
    interpreter = ["powershell.exe", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-Command"]
    command     = "& '${abspath(path.module)}/scripts/finalizar-kubernetes.ps1' -Region '${var.region}' -NombreProyecto '${var.nombre_proyecto}' -Instancias '${join(",", module.compute.instance_ids)}' -EfsId '${module.storage.efs_id}' -Url 'http://${module.compute.alb_dns}' -Correo '${var.alerta_mail}' -ManifestPath '${abspath("${path.module}/../kubernetes/app.yaml")}' -ExpectedAccount '${data.aws_caller_identity.deploy.account_id}'"
  }
}


