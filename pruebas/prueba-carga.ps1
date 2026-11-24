#Requires -Version 5.1
<#
.SYNOPSIS
  Ejecuta la prueba de carga k6 contra el ALB de Online Boutique.

.EXAMPLE
  .\pruebas\prueba-carga.ps1 -Pico 150

.NOTES
  Requiere k6 (winget install k6). Mientras corre, en otra terminal se puede observar el escalado:
    aws ssm start-session --target <id-instancia>   # luego: kubectl get hpa -w
#>
param(
    [int]$Pico = 100
)
$ErrorActionPreference = 'Stop'
if (-not (Get-Command k6 -ErrorAction SilentlyContinue)) {
    throw 'k6 no esta instalado. Instalar con: winget install k6'
}
Push-Location (Join-Path (Split-Path $PSScriptRoot -Parent) 'terraform')
try { $url = (& terraform output -raw url_online_boutique | Out-String).Trim() } finally { Pop-Location }
Write-Host "Carga sobre $url con pico de $Pico usuarios virtuales (6 minutos)"
& k6 run -e "URL=$url" -e "PICO=$Pico" (Join-Path $PSScriptRoot 'carga.k6.js')
