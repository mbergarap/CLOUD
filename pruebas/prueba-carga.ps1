
#Requires -Version 5.1

<#
.SYNOPSIS
  EJECUTA UNA PRUEBA DE CARGA CON K6 CONTRA EL ALB DE ONLINE BOUTIQUE.

.EXAMPLE
  .\pruebas\prueba-carga.ps1 -Pico 150

.NOTES
  REQUIERE K6 (WINGET INSTALL K6).
  DURANTE LA PRUEBA, PERMITE OBSERVAR EL ESCALADO DE KUBERNETES DESDE OTRA TERMINAL:
  AWS SSM START-SESSION --TARGET <id-instancia>
  KUBECTL GET HPA -W
#>

# DEFINE LA CANTIDAD MAXIMA DE USUARIOS VIRTUALES, CON UN VALOR PREDETERMINADO DE 100.
param(
    [int]$Pico = 100
)
$ErrorActionPreference = 'Stop'

# VERIFICA QUE K6 ESTE INSTALADO ANTES DE EJECUTAR LA PRUEBA.
if (-not (Get-Command k6 -ErrorAction SilentlyContinue)) {
    throw 'k6 no esta instalado. Instalar con: winget install k6'
}

# CONSULTA LOS OUTPUTS DE TERRAFORM PARA OBTENER LA URL DE ONLINE BOUTIQUE.
Push-Location (Join-Path (Split-Path $PSScriptRoot -Parent) 'terraform')
try { $url = (& terraform output -raw url_online_boutique | Out-String).Trim() } finally { Pop-Location }

# EJECUTA LA PRUEBA DE CARGA CON K6 UTILIZANDO LA URL Y EL PICO DE USUARIOS CONFIGURADO.
Write-Host "Carga sobre $url con pico de $Pico usuarios virtuales (6 minutos)"
& k6 run -e "URL=$url" -e "PICO=$Pico" (Join-Path $PSScriptRoot 'carga.k6.js')
