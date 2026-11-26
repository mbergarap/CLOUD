#Requires -Version 5.1
param(
    [Parameter(Mandatory=$true)][string]$Region,
    [Parameter(Mandatory=$true)][string]$Bucket,
    [Parameter(Mandatory=$true)][string]$ExpectedAccount
)
$ErrorActionPreference = 'Stop'

function Invoke-AwsCli([string[]]$ArgsList) {
    $r = & aws @ArgsList 2>&1
    if ($LASTEXITCODE -ne 0) { throw "AWS CLI ($($ArgsList[0..1] -join ' ')): $($r | Out-String)" }
    return ($r | Out-String).Trim()
}

if (-not (Get-Command aws -ErrorAction SilentlyContinue)) { throw 'AWS CLI no esta instalado.' }
$account = Invoke-AwsCli @('sts','get-caller-identity','--query','Account','--output','text')
if ($account -ne $ExpectedAccount) { throw "La cuenta AWS CLI no coincide con la cuenta del proveedor Terraform." }
if ($account -notmatch '^\d{12}$' -or $Bucket -notlike "*-$account") {
    throw 'Cuenta AWS y nombre del bucket no coinciden. Se detiene por seguridad.'
}
$all = Invoke-AwsCli @('s3api','list-buckets','--query','Buckets[].Name','--output','text')
if (@($all -split '\s+') -notcontains $Bucket) {
    Invoke-AwsCli @('s3api','create-bucket','--bucket',$Bucket,'--region',$Region) | Out-Null
    Write-Host "Creado bucket de snapshots: $Bucket"
} else {
    Write-Host "Bucket de snapshots existente: $Bucket"
}
Invoke-AwsCli @('s3api','put-public-access-block','--bucket',$Bucket,
    '--public-access-block-configuration',
    'BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true') | Out-Null

function ArchivoJson($Objeto) {
    $path = Join-Path $env:TEMP ("isc-" + [guid]::NewGuid().ToString('N') + '.json')
    [IO.File]::WriteAllText($path, ($Objeto | ConvertTo-Json -Depth 10 -Compress), [Text.UTF8Encoding]::new($false))
    return $path
}
$encryption = ArchivoJson @{ Rules = @(@{ ApplyServerSideEncryptionByDefault = @{ SSEAlgorithm = 'AES256' } }) }
$lifecycle = ArchivoJson @{ Rules = @(@{ ID = 'retencion-etcd'; Status = 'Enabled'; Filter = @{ Prefix = 'snapshots/' }; Expiration = @{ Days = 7 } }) }
try {
    Invoke-AwsCli @('s3api','put-bucket-encryption','--bucket',$Bucket,'--server-side-encryption-configuration',('file://' + ($encryption -replace '\\','/'))) | Out-Null
    Invoke-AwsCli @('s3api','put-bucket-lifecycle-configuration','--bucket',$Bucket,'--lifecycle-configuration',('file://' + ($lifecycle -replace '\\','/'))) | Out-Null
} finally {
    Remove-Item $encryption,$lifecycle -ErrorAction SilentlyContinue
}
Write-Host "Bucket etcd protegido y configurado: $Bucket"

