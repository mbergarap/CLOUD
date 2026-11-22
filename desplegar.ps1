
$ErrorActionPreference = "Stop"
$env:AWS_DEFAULT_REGION = "us-east-1"
$env:AWS_PAGER = ""
$raiz = $PSScriptRoot
$plan = $null
$vars = @("nombre_bucket_estado","nombre_bucket_aplicacion","cidr_ssh_bastion","ruta_clave_publica_ssh","id_ami_bastion","correo_alertas","nombre_perfil_iam_k3s","region_aws")

function Check { if ($LASTEXITCODE -ne 0) { throw "Error en el paso anterior." } }

try {
    $cuenta = (aws sts get-caller-identity --query Account --output text).Trim()
    Check
    if ($cuenta -notmatch '^\d{12}$') { throw "Cuenta AWS invalida." }
    if ($env:CLOUD_CUENTA_ESPERADA -and $cuenta -ne $env:CLOUD_CUENTA_ESPERADA) { throw "Cuenta AWS incorrecta." }
    Write-Host "Cuenta: $cuenta"

    $ip = Read-Host "IP publica SSH (x.x.x.x/32)"
    if ($ip -notmatch '^(\d{1,3}\.){3}\d{1,3}/32$' -or @((($ip -split '/')[0] -split '\.') | Where-Object { [int]$_ -gt 255 }).Count) { throw "IP invalida." }

    $directorioSSH = Join-Path $env:USERPROFILE ".ssh"
    $privada = Join-Path $directorioSSH "cloud-obligatorio"
    $ssh = "$privada.pub"

    if (-not (Test-Path $directorioSSH -PathType Container)) {
        New-Item -ItemType Directory -Path $directorioSSH -Force | Out-Null
    }

    if ((Test-Path $privada) -and -not (Test-Path $ssh)) {
        throw "Existe una clave privada sin su clave publica. Revisar SSH."
    }

    if (-not (Test-Path $privada) -and (Test-Path $ssh)) {
        throw "Existe una clave publica sin su clave privada. Revisar SSH."
    }

    if (-not (Test-Path $ssh)) {
        if (-not (Get-Command ssh-keygen -ErrorAction SilentlyContinue)) {
            throw "No se encontro ssh-keygen."
        }

        & ssh-keygen -q -t ed25519 -f $privada -N '""'
        Check
    }

    if (-not (Test-Path $ssh -PathType Leaf)) {
        throw "No se pudo preparar la clave SSH."
    }

    Write-Host "Clave SSH: $ssh"

    $correo = Read-Host "Correo alertas"
    if ($correo -notmatch '^[^@\s]+@[^@\s]+\.[^@\s]+$') { throw "Correo invalido." }


    $ami = aws ssm get-parameter --name "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64" --query Parameter.Value --output text
    Check
    $bucket = "cloud-obligatorio-tfstate-$cuenta"

    $env:TF_VAR_nombre_bucket_estado = $bucket
    $env:TF_VAR_nombre_bucket_aplicacion = "cloud-obligatorio-app-$cuenta"
    $env:TF_VAR_cidr_ssh_bastion = $ip
    $env:TF_VAR_ruta_clave_publica_ssh = $ssh
    $env:TF_VAR_id_ami_bastion = $ami.Trim()
    $env:TF_VAR_correo_alertas = $correo
    $perfil = "LabInstanceProfile"
    if (-not [string]::IsNullOrWhiteSpace($env:CLOUD_PERFIL_IAM_K3S)) {
        $perfil = $env:CLOUD_PERFIL_IAM_K3S
    }

    if ($perfil -notmatch '^[A-Za-z0-9+=,.@_-]+$') {
        throw "Perfil IAM invalido."
    }

    $rolIAM = aws iam get-instance-profile --instance-profile-name $perfil --query "InstanceProfile.Roles[0].RoleName" --output text
    Check

    if (-not $rolIAM -or $rolIAM.Trim() -eq "None") {
        throw "El perfil IAM no tiene un rol asociado."
    }

    Write-Host "Perfil IAM: $perfil"
    $env:TF_VAR_nombre_perfil_iam_k3s = $perfil
    $env:TF_VAR_region_aws = "us-east-1"



    terraform "-chdir=$raiz\bootstrap" init -backend=false -input=false | Out-Null
    Check
    terraform "-chdir=$raiz\bootstrap" apply -auto-approve -input=false
    Check

    aws s3api head-bucket --bucket $bucket --expected-bucket-owner $cuenta | Out-Null
    Check

    terraform "-chdir=$raiz\terraform" init -reconfigure -input=false "-backend-config=bucket=$bucket"
    Check


    $plan = Join-Path $env:TEMP "cloud-$cuenta-$([guid]::NewGuid().ToString('N')).tfplan"
    terraform "-chdir=$raiz\terraform" plan -input=false "-out=$plan"
    Check

    $json = terraform "-chdir=$raiz\terraform" show -json $plan | ConvertFrom-Json
    Check
    foreach ($r in @($json.resource_changes)) {
        if (@($r.change.actions | Where-Object { $_ -in "update","delete" }).Count) { throw "Plan destructivo bloqueado." }
    }

    terraform "-chdir=$raiz\terraform" apply -input=false $plan
    Check
    $dns = terraform "-chdir=$raiz\terraform" output -raw nombre_dns_alb
    Check
    Write-Host "Despliegue completado: http://$dns/" -ForegroundColor Green
}
finally {
    foreach ($v in $vars) { Remove-Item "Env:TF_VAR_$v" -ErrorAction SilentlyContinue }
    if ($plan -and (Test-Path $plan)) { Remove-Item $plan -Force }
}
