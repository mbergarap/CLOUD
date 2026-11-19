terraform {
  required_version = ">= 1.5.0"
}

resource "terraform_data" "backend_bucket" {

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]

    command = <<EOT
$ErrorActionPreference = "Stop"

$bucket = "cloud-obligatorio-tfstate-2026"

aws s3api head-bucket --bucket $bucket 2>$null

if ($LASTEXITCODE -ne 0) {
    aws s3api create-bucket --bucket $bucket --region us-east-1
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
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