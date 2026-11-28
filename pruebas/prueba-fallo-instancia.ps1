
#Requires -Version 5.1

<#
.SYNOPSIS
  EJECUTA UNA PRUEBA DE TOLERANCIA A FALLOS DETENIENDO UNA INSTANCIA K3S Y VERIFICANDO LA DISPONIBILIDAD DE ONLINE BOUTIQUE.

.DESCRIPTION
  1. OBTIENE LAS INSTANCIAS EC2 Y LA URL DE LA APLICACION DESDE TERRAFORM.
  2. COMPRUEBA QUE LOS TRES DESTINOS DEL ALB ESTEN SALUDABLES.
  3. DETIENE UNA INSTANCIA PARA SIMULAR LA PERDIDA DE UN NODO EN UNA ZONA DE DISPONIBILIDAD.
  4. MONITOREA LAS RESPUESTAS HTTP Y LA SALUD DE LOS DESTINOS CADA 5 SEGUNDOS.
  5. REINICIA LA INSTANCIA Y ESPERA QUE VUELVA A ESTAR SALUDABLE.
  6. MUESTRA LOS RESULTADOS Y GUARDA LAS MEDICIONES EN UN ARCHIVO CSV.

  LA PRUEBA UTILIZA STOP/START Y NO ELIMINA RECURSOS NI MODIFICA TERRAFORM.

.EXAMPLE
  .\pruebas\prueba-fallo-instancia.ps1 -Indice 1
#>

# DEFINE LA INSTANCIA A DETENER, LA DURACION DE LA PRUEBA, LA REGION Y EL ARCHIVO DE RESULTADOS.
param(
    [ValidateRange(0, 2)][int]$Indice = 1,
    [int]$DuracionMinutos = 5,
    [string]$Region = 'us-east-1',
    [string]$Salida = (Join-Path $PSScriptRoot 'resultado-fallo-instancia.csv')
)
$ErrorActionPreference = 'Stop'
$tf = Join-Path (Split-Path $PSScriptRoot -Parent) 'terraform'

# EJECUTA COMANDOS DE AWS CLI Y DETIENE LA PRUEBA SI SE PRODUCE UN ERROR.
function Aws($argumentos) {
    $r = & aws.exe @argumentos
    if ($LASTEXITCODE -ne 0) { throw "AWS fallo: $($argumentos -join ' ')" }
    return ($r | Out-String).Trim()
}

# OBTIENE DESDE TERRAFORM LOS IDENTIFICADORES DE LAS INSTANCIAS Y LA URL DE ONLINE BOUTIQUE.
Push-Location $tf
try {
    $json = (& terraform output -json instancias_k3s | Out-String)
    $ids = [string[]](ConvertFrom-Json -InputObject $json)
    $url = (& terraform output -raw url_online_boutique | Out-String).Trim()
} finally { Pop-Location }
if ($ids.Count -ne 3) { throw 'No se obtuvieron las tres instancias desde Terraform' }

# SELECCIONA LA INSTANCIA A DETENER E IDENTIFICA EL TARGET GROUP DEL ALB.
$objetivo = [string]$ids[$Indice]
$grupo = Aws @('elbv2', 'describe-target-groups', '--region', $Region, '--names', 'isc-obligatorio-web',
    '--query', 'TargetGroups[0].TargetGroupArn', '--output', 'text')

# CONSULTA EL ESTADO DE LOS DESTINOS DEL ALB Y DEVUELVE LA CANTIDAD DE INSTANCIAS SALUDABLES.
function Sanos() {
    $estados = Aws @('elbv2', 'describe-target-health', '--region', $Region, '--target-group-arn', $grupo,
        '--query', 'TargetHealthDescriptions[].TargetHealth.State', '--output', 'text')
    return @($estados -split '\s+' | Where-Object { $_ -eq 'healthy' }).Count
}

# REALIZA UNA PETICION HTTP Y DEVUELVE EL CODIGO DE RESPUESTA O CERO SI NO HAY RESPUESTA.
function Http() {
    try { return [int](Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 10).StatusCode }
    catch {
        if ($_.Exception.Response) { return [int]$_.Exception.Response.StatusCode }
        return 0
    }
}

# VERIFICA QUE LOS TRES DESTINOS ESTEN SALUDABLES ANTES DE COMENZAR LA PRUEBA.
Write-Host "URL: $url"
Write-Host "Instancia a detener: $objetivo (indice $Indice)"
$antes = Sanos
Write-Host "Targets sanos antes de la prueba: $antes de 3"
if ($antes -lt 3) { throw 'Deben estar los 3 targets sanos antes de comenzar' }

# PREPARA EL REGISTRO DE MEDICIONES Y DETIENE LA INSTANCIA EC2 SELECCIONADA.
$filas = New-Object System.Collections.Generic.List[object]
$inicio = Get-Date
Write-Host "`n[$(Get-Date -Format HH:mm:ss)] Deteniendo $objetivo ..." -ForegroundColor Yellow
Aws @('ec2', 'stop-instances', '--region', $Region, '--instance-ids', $objetivo) | Out-Null

# MONITOREA CADA 5 SEGUNDOS LAS RESPUESTAS HTTP Y LOS DESTINOS SANOS DURANTE LA PRUEBA.
# AL FINALIZAR, INTENTA VOLVER A ENCENDER LA INSTANCIA, INCLUSO SI OCURRE UN ERROR.
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

# ESPERA QUE LA INSTANCIA SE REINCORPORE Y EL ALB RECUPERE SUS TRES DESTINOS SALUDABLES.
$recuperado = $false
for ($i = 0; $i -lt 60; $i++) {
    if ((Sanos) -ge 3) { $recuperado = $true; break }
    Start-Sleep 15
}

# GUARDA LAS MEDICIONES EN CSV Y CALCULA LA DISPONIBILIDAD OBSERVADA DURANTE LA PRUEBA.
$filas | Export-Csv -NoTypeInformation -Path $Salida -Encoding UTF8
$total = $filas.Count
$ok = @($filas | Where-Object { $_.http -eq 200 }).Count
$minSanos = ($filas | Measure-Object -Property targets_sanos -Minimum).Minimum

# MUESTRA LA CANTIDAD DE RESPUESTAS EXITOSAS, EL PORCENTAJE DE DISPONIBILIDAD Y LA RECUPERACION DEL ALB.
Write-Host "`n===== RESUMEN =====" -ForegroundColor Cyan
Write-Host "Consultas HTTP: $total  |  HTTP 200: $ok  |  Disponibilidad: $([math]::Round(100 * $ok / [math]::Max($total,1), 2)) %"
Write-Host "Minimo de targets sanos durante la prueba: $minSanos"
Write-Host "Recuperacion a 3 targets sanos: $recuperado"
Write-Host "Detalle guardado en: $Salida"

