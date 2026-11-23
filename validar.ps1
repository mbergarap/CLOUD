#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
$raiz = Split-Path -Parent $MyInvocation.MyCommand.Path

function Revisar($titulo, [scriptblock]$accion) {
    Write-Host $titulo
    try {
        & $accion
        Write-Host "OK`n"
    } catch {
        Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

Revisar 'Configuracion' {
    $ruta = Join-Path $raiz 'config.psd1'
    if (-not (Test-Path $ruta)) { throw 'Falta config.psd1' }
    $config = Import-PowerShellDataFile -Path $ruta
    if ($config.alerta_mail -notmatch '^[^\s@]+@[^\s@]+\.[^\s@]+$' -or $config.alerta_mail -eq 'correo@ejemplo.com') {
        throw 'Complete alerta_mail con un correo valido.'
    }
    if ($config.nombre_bucket -notmatch '^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$' -or $config.nombre_bucket -eq 'nombre-unico-del-bucket') {
        throw 'Complete nombre_bucket: 3-63 caracteres minusculas/numeros/guiones/puntos.'
    }
    if ($config.nombre_bucket -match '(\.\.|\.-|-\.)' -or $config.nombre_bucket -match '^\d+\.\d+\.\d+\.\d+$') {
        throw 'Nombre de bucket S3 invalido.'
    }
}
Revisar 'AWS CLI' {
    if (-not (Get-Command aws -ErrorAction SilentlyContinue)) { throw 'Instale AWS CLI v2.' }
    & aws --version
    if ($LASTEXITCODE -ne 0) { throw 'AWS CLI no responde.' }
}
Revisar 'Credenciales AWS' {
    $identidad = & aws sts get-caller-identity --query Account --output text
    if ($LASTEXITCODE -ne 0 -or -not $identidad) { throw 'Credenciales AWS incorrectas o vencidas.' }
}
Revisar 'Terraform' {
    if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) { throw 'Instale Terraform.' }
    & terraform version
    if ($LASTEXITCODE -ne 0) { throw 'Terraform no responde.' }
}
Revisar 'Archivos del proyecto' {
    foreach ($ruta in @('terraform/main.tf','terraform/providers.tf','terraform/outputs.tf','kubernetes/app.yaml','desplegar.ps1')) {
        if (-not (Test-Path (Join-Path $raiz $ruta))) { throw "No existe $ruta" }
    }
}
Revisar 'Validacion Terraform' {
    Push-Location (Join-Path $raiz 'terraform')
    try {
        & terraform fmt -recursive
        if ($LASTEXITCODE -ne 0) { throw 'Ejecute terraform fmt -recursive; hay archivos sin formato.' }
        & terraform init -backend=false -input=false
        if ($LASTEXITCODE -ne 0) { throw 'Fallo terraform init -backend=false.' }
        & terraform validate
        if ($LASTEXITCODE -ne 0) { throw 'Fallo terraform validate.' }
    } finally { Pop-Location }
}
