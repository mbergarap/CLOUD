
# =========================
# S3 - AWS ACADEMY
# =========================

# AWS Academy puede restringir la creación de buckets
# mediante el provider de Terraform.
# Por eso utilizamos AWS CLI desde PowerShell.

resource "terraform_data" "app_bucket" {
  count = var.use_native_s3 ? 0 : 1

  input = var.bucket_name

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]

    command = <<-EOT
      $ErrorActionPreference = "Stop"
      $bucket = "${var.bucket_name}"
      $region = "${var.aws_region}"

      # Comprobar si existe el bucket.
      aws s3api head-bucket --bucket $bucket 2>$null

      if ($LASTEXITCODE -ne 0) {
        Write-Host "Intentando crear bucket: $bucket"

        if ($region -eq "us-east-1") {
          aws s3api create-bucket --bucket $bucket --region $region
        } else {
          aws s3api create-bucket --bucket $bucket --region $region --create-bucket-configuration LocationConstraint=$region
        }

        if ($LASTEXITCODE -ne 0) {
          throw "No se pudo crear el bucket. Verificar permisos y nombre."
        }
      }

      # Versionado
      aws s3api put-bucket-versioning --bucket $bucket --versioning-configuration Status=Enabled
      if ($LASTEXITCODE -ne 0) { throw "Error configurando versionado" }

      # Bloquear acceso publico
      aws s3api put-public-access-block --bucket $bucket --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
      if ($LASTEXITCODE -ne 0) { throw "Error configurando acceso publico" }

      # Cifrado SSE-S3
      $encryptionFile = Join-Path $env:TEMP "cloud-app-encryption.json"

      $encryption = @{
        Rules = @(
          @{
            ApplyServerSideEncryptionByDefault = @{
              SSEAlgorithm = "AES256"
            }
          }
        )
      }

      $encryption | ConvertTo-Json -Depth 10 | Set-Content $encryptionFile -Encoding ASCII

      aws s3api put-bucket-encryption --bucket $bucket --server-side-encryption-configuration "file://$encryptionFile"
      if ($LASTEXITCODE -ne 0) { throw "Error configurando cifrado" }

      # Eliminar versiones no actuales despues de 30 dias
      $lifecycleFile = Join-Path $env:TEMP "cloud-app-lifecycle.json"

      $lifecycle = @{
        Rules = @(
          @{
            ID = "EliminarVersionesAntiguas"
            Status = "Enabled"
            Filter = @{}
            NoncurrentVersionExpiration = @{
              NoncurrentDays = 30
            }
          }
        )
      }

      $lifecycle | ConvertTo-Json -Depth 10 | Set-Content $lifecycleFile -Encoding ASCII

      aws s3api put-bucket-lifecycle-configuration --bucket $bucket --lifecycle-configuration "file://$lifecycleFile"
      if ($LASTEXITCODE -ne 0) { throw "Error configurando lifecycle" }

      Remove-Item $encryptionFile, $lifecycleFile -ErrorAction SilentlyContinue

      Write-Host "Bucket S3 configurado correctamente."
    EOT
  }

  # No vaciamos ni eliminamos automaticamente el bucket.
  # Terraform solo administra este recurso auxiliar.
}

# =========================
# S3 - AWS ESTANDAR
# =========================

resource "aws_s3_bucket" "app" {
  count = var.use_native_s3 ? 1 : 0

  bucket        = var.bucket_name
  force_destroy = false

  tags = {
    Name    = var.bucket_name
    Project = var.project_name
  }
}

# =========================
# VERSIONADO
# =========================

resource "aws_s3_bucket_versioning" "app" {
  count = var.use_native_s3 ? 1 : 0

  bucket = aws_s3_bucket.app[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

# =========================
# BLOQUEO DE ACCESO PUBLICO
# =========================

resource "aws_s3_bucket_public_access_block" "app" {
  count = var.use_native_s3 ? 1 : 0

  bucket = aws_s3_bucket.app[0].id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# =========================
# CIFRADO SSE-S3
# =========================

resource "aws_s3_bucket_server_side_encryption_configuration" "app" {
  count = var.use_native_s3 ? 1 : 0

  bucket = aws_s3_bucket.app[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# =========================
# LIFECYCLE
# =========================

resource "aws_s3_bucket_lifecycle_configuration" "app" {
  count = var.use_native_s3 ? 1 : 0

  bucket = aws_s3_bucket.app[0].id

  rule {
    id     = "EliminarVersionesAntiguas"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.app
  ]
}

# =========================
# EMPAQUETADO DE LA APLICACION
# =========================

data "archive_file" "app" {
  type        = "zip"
  source_dir  = var.app_source_dir
  output_path = var.app_zip_path
}

# =========================
# SUBIDA DE APP.ZIP
# =========================

resource "aws_s3_object" "app" {
  bucket = var.bucket_name
  key    = "app.zip"

  source = data.archive_file.app.output_path
  etag   = filemd5(data.archive_file.app.output_path)

  depends_on = [
    terraform_data.app_bucket,
    aws_s3_bucket.app,
    aws_s3_bucket_versioning.app,
    aws_s3_bucket_public_access_block.app,
    aws_s3_bucket_server_side_encryption_configuration.app
  ]
}
