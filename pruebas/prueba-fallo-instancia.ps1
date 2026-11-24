#Requires -Version 5.1
<#
.SYNOPSIS
  Prueba de tolerancia a fallos: detiene UNA instancia K3s y mide si Online Boutique sigue respondiendo.

.DESCRIPTION
  1. Lee las tres instancias y la URL desde las salidas de Terraform.
  2. Verifica que el ALB tenga todos los targets sanos.
  3. Detiene la instancia indicada (cada instancia esta en una AZ distinta, por lo que
     equivale a perder una zona de disponibilidad).
  4. Durante $DuracionMinutos consulta la URL cada 5 segundos y registra el codigo HTTP y la salud de los targets.
  5. Vuelve a iniciar la instancia y espera a que el ALB la vea sana.
  6. Muestra un resumen y guarda el detalle en un CSV.

  Es una prueba controlada y reversible (stop/start): no elimina recursos ni modifica Terraform.

.EXAMPLE
  .\pruebas\prueba-fallo-instancia.ps1 -Indice 1
#>
param(
    [ValidateRange(0, 2)][int]$Indice = 1,
    [int]$DuracionMinutos = 5,
    [string]$Region = 'us-east-1',
    [string]$Salida = (Join-Path $PSScriptRoot 'resultado-fallo-instancia.csv')
)
$ErrorActionPreference = 'Stop'
$tf = Join-Path (Split-Path $PSScriptRoot -Parent) 'terraform'

function Aws($argumentos) {
    $r = & aws @argumentos
    if ($LASTEXITCODE -ne 0) { throw "AWS fallo: $($argumentos -join ' ')" }
    return ($r | Out-String).Trim()
}

Push-Location $tf
try {
    $ids = @(ConvertFrom-Json -InputObject ((& terraform output -json instancias_k3s) | Out-String))
    $url = (& terraform output -raw url_online_boutique | Out-String).Trim()
} finally { Pop-Location }
if ($ids.Count -ne 3) { throw 'No se obtuvieron las tres instancias desde Terraform' }

$objetivo = [string]$ids[$Indice]
$grupo = Aws @('elbv2', 'describe-target-groups', '--region', $Region, '--names', 'isc-obligatorio-web',
    '--query', 'TargetGroups[0].TargetGroupArn', '--output', 'text')

function Sanos() {
    $estados = Aws @('elbv2', 'describe-target-health', '--region', $Region, '--target-group-arn', $grupo,
        '--query', 'TargetHealthDescriptions[].TargetHealth.State', '--output', 'text')
    return @($estados -split '\s+' | Where-Object { $_ -eq 'healthy' }).Count
}

function Http() {
    try { return [int](Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 10).StatusCode }
    catch {
        if ($_.Exception.Response) { return [int]$_.Exception.Response.StatusCode }
        return 0
    }
}

Write-Host "URL: $url"
Write-Host "Instancia a detener: $objetivo (indice $Indice)"
$antes = Sanos
Write-Host "Targets sanos antes de la prueba: $antes de 3"
if ($antes -lt 3) { throw 'Deben estar los 3 targets sanos antes de comenzar' }

$filas = New-Object System.Collections.Generic.List[object]
$inicio = Get-Date
Write-Host "`n[$(Get-Date -Format HH:mm:ss)] Deteniendo $objetivo ..." -ForegroundColor Yellow
Aws @('ec2', 'stop-instances', '--region', $Region, '--instance-ids', $objetivo) | Out-Null

try {
    $fin = $inicio.AddMinutes($DuracionMinutos)
    while ((Get-Date) -lt $fin) {
        $codigo = Http
        $sanos = Sanos
        $t = [int]((Get-Date) - $inicio).TotalSeconds
        $filas.Add([pscustomobject]@{ segundos = $t; http = $codigo; targets_sanos = $sanos })
        Write-Host ("t={0,4}s  HTTP={1}  targets sanos={2}" -f $t, $codigo, $sanos)
        Start-Sleep 5
    }
} finally {
    Write-Host "`n[$(Get-Date -Format HH:mm:ss)] Iniciando $objetivo de nuevo ..." -ForegroundColor Yellow
    Aws @('ec2', 'start-instances', '--region', $Region, '--instance-ids', $objetivo) | Out-Null
}

# Espera a que el ALB vuelva a ver los 3 targets sanos (K3s se reincorpora solo al cluster).
$recuperado = $false
for ($i = 0; $i -lt 60; $i++) {
    if ((Sanos) -ge 3) { $recuperado = $true; break }
    Start-Sleep 15
}

$filas | Export-Csv -NoTypeInformation -Path $Salida -Encoding UTF8
$total = $filas.Count
$ok = @($filas | Where-Object { $_.http -eq 200 }).Count
$minSanos = ($filas | Measure-Object -Property targets_sanos -Minimum).Minimum
Write-Host "`n===== RESUMEN =====" -ForegroundColor Cyan
Write-Host "Consultas HTTP: $total  |  HTTP 200: $ok  |  Disponibilidad: $([math]::Round(100 * $ok / [math]::Max($total,1), 2)) %"
Write-Host "Minimo de targets sanos durante la prueba: $minSanos"
Write-Host "Recuperacion a 3 targets sanos: $recuperado"
Write-Host "Detalle guardado en: $Salida"
