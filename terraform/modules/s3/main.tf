
# S3 EN AWS ACADEMY

# En AWS Academy utilizamos AWS CLI para configurar el bucket,
# ya que el laboratorio puede restringir su creacion desde Terraform.
resource "terraform_data" "app_bucket" {
  count = var.usar_s3_nativo ? 0 : 1

  input = var.nombre_bucket

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]

    command = <<-EOT
      $ErrorActionPreference = "Stop"
      $bucket = "${var.nombre_bucket}"
      $region = "${var.region_aws}"

      # Comprobar si existe el bucket.
      $existingBuckets = aws s3api list-buckets --query "Buckets[].Name" --output text
      if ($LASTEXITCODE -ne 0) {
        throw "No se pudo consultar la lista de buckets S3"
      }

      $bucketExists = @($existingBuckets -split '\s+') -contains $bucket

      if (-not $bucketExists) {
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

      # Habilitar el versionado.
      aws s3api put-bucket-versioning --bucket $bucket --versioning-configuration Status=Enabled
      if ($LASTEXITCODE -ne 0) { throw "Error configurando versionado" }

      # Bloquear el acceso publico.
      aws s3api put-public-access-block --bucket $bucket --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
      if ($LASTEXITCODE -ne 0) { throw "Error configurando acceso publico" }

      # Configurar el cifrado SSE-S3.
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

      # Eliminar las versiones antiguas despues de 30 dias.
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

  # El bucket no se elimina automaticamente junto con este recurso.
}

# S3 CON TERRAFORM

# Alternativa para cuentas AWS que permiten administrar S3 directamente.
resource "aws_s3_bucket" "app" {
  count = var.usar_s3_nativo ? 1 : 0

  bucket        = var.nombre_bucket
  force_destroy = false

  tags = {
    Name    = var.nombre_bucket
    Project = var.nombre_proyecto
  }
}

# VERSIONADO

# Conserva versiones anteriores de los archivos del bucket.
resource "aws_s3_bucket_versioning" "app" {
  count = var.usar_s3_nativo ? 1 : 0

  bucket = aws_s3_bucket.app[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

# BLOQUEO DE ACCESO PUBLICO

# Evita que el bucket quede expuesto mediante ACL o politicas publicas.
resource "aws_s3_bucket_public_access_block" "app" {
  count = var.usar_s3_nativo ? 1 : 0

  bucket = aws_s3_bucket.app[0].id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# CIFRADO

# Cifra los archivos almacenados utilizando SSE-S3.
resource "aws_s3_bucket_server_side_encryption_configuration" "app" {
  count = var.usar_s3_nativo ? 1 : 0

  bucket = aws_s3_bucket.app[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# CICLO DE VIDA

# Elimina versiones anteriores cuando cumplen 30 dias.
resource "aws_s3_bucket_lifecycle_configuration" "app" {
  count = var.usar_s3_nativo ? 1 : 0

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