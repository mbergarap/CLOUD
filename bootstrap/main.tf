terraform {
  required_version = ">= 1.5.0"
}

# Crea (si hace falta) el bucket S3 donde se guarda el estado remoto de Terraform.
resource "terraform_data" "backend_bucket" {
  # Si cambia el nombre del bucket (por ejemplo, otra cuenta AWS), Terraform
  # vuelve a ejecutar el script en vez de dar por hecho que el bucket ya existe.
  triggers_replace = var.nombre_bucket_estado

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]

    command = <<EOT
$ErrorActionPreference = "Stop"

$bucket = "${var.nombre_bucket_estado}"

# Identificamos la cuenta AWS activa.
$account = aws sts get-caller-identity --query Account --output text

if ($LASTEXITCODE -ne 0 -or $account -notmatch '^\d{12}$') {
    throw "No se pudo identificar la cuenta AWS."
}

# Comprobamos que el bucket pertenezca a esa cuenta.
$ErrorActionPreference = "Continue"
aws s3api head-bucket --bucket $bucket --expected-bucket-owner $account 2>$null
$headResult = $LASTEXITCODE
$ErrorActionPreference = "Stop"

if ($headResult -ne 0) {
    # Si el nombre esta disponible, creamos el bucket.
    # Si pertenece a otra cuenta, la creacion debe fallar.
    aws s3api create-bucket --bucket $bucket --region us-east-1

    if ($LASTEXITCODE -ne 0) {
        throw "No se pudo crear el bucket. Revisar nombre, permisos y propietario."
    }
}

# Verificacion obligatoria del propietario.
aws s3api head-bucket --bucket $bucket --expected-bucket-owner $account

if ($LASTEXITCODE -ne 0) {
    throw "El bucket no pertenece a la cuenta AWS activa o no es accesible."
}

aws s3api put-bucket-versioning `
    --bucket $bucket `
    --versioning-configuration Status=Enabled
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

aws s3api put-public-access-block `
    --bucket $bucket `
    --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
EOT
  }
}