resource "terraform_data" "app_bucket" {

  input = var.bucket_name

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]

    command = <<EOT
$bucket = "${var.bucket_name}"

# =========================
# COMPROBAR / CREAR BUCKET
# =========================

cmd /c "aws s3api head-bucket --bucket $bucket >nul 2>&1"

if ($LASTEXITCODE -ne 0) {

    Write-Host "Creando bucket $bucket..."

    aws s3api create-bucket `
        --bucket $bucket `
        --region us-east-1

    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

} else {

    Write-Host "El bucket $bucket ya existe."

}

# =========================
# VERSIONADO
# =========================

Write-Host "Habilitando versionado..."

aws s3api put-bucket-versioning `
    --bucket $bucket `
    --versioning-configuration Status=Enabled

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

# =========================
# BLOQUEO PUBLICO
# =========================

Write-Host "Bloqueando acceso publico..."

aws s3api put-public-access-block `
    --bucket $bucket `
    --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

# =========================
# CIFRADO SSE-S3
# =========================

Write-Host "Configurando cifrado SSE-S3..."

$encryptionFile = Join-Path $env:TEMP "s3-encryption.json"

$encryption = @{
    Rules = @(
        @{
            ApplyServerSideEncryptionByDefault = @{
                SSEAlgorithm = "AES256"
            }
        }
    )
}

$encryption |
    ConvertTo-Json -Depth 10 |
    Set-Content -Path $encryptionFile -Encoding ASCII

aws s3api put-bucket-encryption `
    --bucket $bucket `
    --server-side-encryption-configuration "file://$encryptionFile"

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

# =========================
# LIFECYCLE
# =========================

Write-Host "Configurando lifecycle..."

$lifecycleFile = Join-Path $env:TEMP "s3-lifecycle.json"

$lifecycle = @{
    Rules = @(
        @{
            ID     = "EliminarVersionesAntiguas"
            Status = "Enabled"
            Filter = @{}

            NoncurrentVersionExpiration = @{
                NoncurrentDays = 30
            }
        }
    )
}

$lifecycle |
    ConvertTo-Json -Depth 10 |
    Set-Content -Path $lifecycleFile -Encoding ASCII

aws s3api put-bucket-lifecycle-configuration `
    --bucket $bucket `
    --lifecycle-configuration "file://$lifecycleFile"

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

# =========================
# LIMPIEZA ARCHIVOS TEMPORALES
# =========================

Remove-Item $encryptionFile -ErrorAction SilentlyContinue
Remove-Item $lifecycleFile -ErrorAction SilentlyContinue

Write-Host "Bucket configurado correctamente."
EOT
  }

  # =========================
  # DESTRUCCION DEL BUCKET
  # =========================

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["PowerShell", "-Command"]

    command = <<EOT
$bucket = "${self.input}"

Write-Host "Vaciando bucket versionado $bucket..."

# =========================
# ELIMINAR VERSIONES
# =========================

$objects = aws s3api list-object-versions `
    --bucket $bucket `
    --output json | ConvertFrom-Json

if ($objects.Versions) {

    foreach ($version in $objects.Versions) {

        Write-Host "Eliminando version $($version.VersionId) de $($version.Key)"

        aws s3api delete-object `
            --bucket $bucket `
            --key $version.Key `
            --version-id $version.VersionId

        if ($LASTEXITCODE -ne 0) {
            exit $LASTEXITCODE
        }
    }
}

# =========================
# ELIMINAR DELETE MARKERS
# =========================

if ($objects.DeleteMarkers) {

    foreach ($marker in $objects.DeleteMarkers) {

        Write-Host "Eliminando delete marker $($marker.VersionId) de $($marker.Key)"

        aws s3api delete-object `
            --bucket $bucket `
            --key $marker.Key `
            --version-id $marker.VersionId

        if ($LASTEXITCODE -ne 0) {
            exit $LASTEXITCODE
        }
    }
}

# =========================
# ABORTAR MULTIPART UPLOADS
# =========================

$uploads = aws s3api list-multipart-uploads `
    --bucket $bucket `
    --output json | ConvertFrom-Json

if ($uploads.Uploads) {

    foreach ($upload in $uploads.Uploads) {

        Write-Host "Cancelando multipart upload de $($upload.Key)"

        aws s3api abort-multipart-upload `
            --bucket $bucket `
            --key $upload.Key `
            --upload-id $upload.UploadId

        if ($LASTEXITCODE -ne 0) {
            exit $LASTEXITCODE
        }
    }
}

# =========================
# BORRAR BUCKET
# =========================

Write-Host "Eliminando bucket $bucket..."

aws s3api delete-bucket `
    --bucket $bucket

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Host "Bucket eliminado correctamente."
EOT
  }
}

# =========================
# EMPAQUETADO DE LA APP
# =========================

data "archive_file" "app" {
  type        = "zip"
  source_dir  = var.app_source_dir
  output_path = var.app_zip_path
}

# =========================
# SUBIDA DE APP.ZIP A S3
# =========================

resource "aws_s3_object" "app" {
  bucket = var.bucket_name
  key    = "app.zip"

  source = data.archive_file.app.output_path
  etag   = filemd5(data.archive_file.app.output_path)

  depends_on = [
    terraform_data.app_bucket
  ]
}