
#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
$raiz = $PSScriptRoot
$region = 'us-east-1'
$tf = Join-Path $raiz 'terraform'

function EjecutarAws($argsList) {
    $salida = & aws @argsList
    if ($LASTEXITCODE -ne 0) { throw "AWS: $($argsList -join ' ')" }
    return ($salida | Out-String).Trim()
}

function Tf($argsList) {
    & terraform @argsList
    if ($LASTEXITCODE -ne 0) { throw "Terraform: $($argsList -join ' ')" }
}

function Etapa($nombre, [scriptblock]$accion) {
    Write-Host "`n$nombre" -ForegroundColor Cyan
    & $accion
    Write-Host 'OK' -ForegroundColor Green
}

function JsonTemporal($datos) {
    $ruta = Join-Path $env:TEMP ("isc-" + [guid]::NewGuid().ToString('N') + '.json')
    $json = $datos | ConvertTo-Json -Depth 8 -Compress
    [IO.File]::WriteAllText($ruta, $json, [Text.UTF8Encoding]::new($false))
    return $ruta
}

function Ssm($instancia, [string[]]$comandos) {
    $archivo = JsonTemporal @{
        commands = $comandos
        executionTimeout = @('3600')
    }
    try {
        $uri = 'file://' + ($archivo -replace '\\','/')
        $id = EjecutarAws @(
            'ssm','send-command','--region',$region,
            '--instance-ids',$instancia,
            '--document-name','AWS-RunShellScript',
            '--parameters',$uri,'--query','Command.CommandId','--output','text'
        )
    } finally {
        Remove-Item $archivo -ErrorAction SilentlyContinue
    }
    for ($i = 0; $i -lt 240; $i++) {
        Start-Sleep 15
        try {
            $r = EjecutarAws @(
                'ssm','get-command-invocation','--region',$region,
                '--command-id',$id,'--instance-id',$instancia,'--output','json'
            ) | ConvertFrom-Json
        } catch { continue }
        if ($r.Status -eq 'Success') { return $r.StandardOutputContent }
        if ($r.Status -in @('Failed','Cancelled','TimedOut','Cancelling')) {
            throw "SSM $instancia : $($r.Status) $($r.StandardOutputContent) $($r.StandardErrorContent)"
        }
    }
    throw "SSM sin respuesta: $id"
}

Etapa 'Configuracion' {
    foreach ($programa in @('aws','terraform')) {
        if (-not (Get-Command $programa -ErrorAction SilentlyContinue)) {
            throw "Falta instalar $programa"
        }
    }
    $cuenta = EjecutarAws @('sts','get-caller-identity','--query','Account','--output','text')
    if ($cuenta -notmatch '^\d{12}$') { throw 'Credenciales AWS invalidas' }
    $archivoConfig = Join-Path $raiz 'config.psd1'
    $config = @{}
    if (Test-Path $archivoConfig) {
        $config = Import-PowerShellDataFile $archivoConfig
    }
    $script:mail = [string]$config.alerta_mail
    if ([string]::IsNullOrWhiteSpace($mail) -or $mail -eq 'correo@ejemplo.com') {
        $script:mail = Read-Host 'Correo obligatorio de alertas SNS'
    }
    if ($mail -notmatch '^[^\s@]+@[^\s@]+\.[^\s@]+$') {
        throw 'Correo SNS invalido'
    }
    $script:bucket = [string]$config.nombre_bucket
    if ([string]::IsNullOrWhiteSpace($bucket) -or $bucket -eq 'nombre-unico-del-bucket') {
        $script:bucket = "isc-obligatorio-tfstate-$cuenta"
    }
    if ($bucket -notmatch '^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$' -or
        $bucket -match '(\.\.|\.-|-\.)|^\d+\.\d+\.\d+\.\d+$') {
        throw 'Nombre del bucket backend invalido'
    }
    $script:sshCidr = Read-Host 'Tu IP publica autorizada para SSH (formato X.X.X.X/32; SSH permanece cerrado y se usa SSM)'
    $partes = $sshCidr -split '/'
    $ipValida = $false
    if ($partes.Count -eq 2 -and $partes[1] -eq '32') {
        $ip = $null
        $ipValida = [System.Net.IPAddress]::TryParse($partes[0], [ref]$ip) -and
            $ip.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork
    }
    if (-not $ipValida) { throw 'IP autorizada invalida: usar IPv4/32' }
    $env:TF_VAR_alerta_mail = $mail
    $env:AWS_DEFAULT_REGION = $region

}

Etapa 'Backend S3' {
    $lista = EjecutarAws @('s3api','list-buckets','--query','Buckets[].Name','--output','text')
    if (@($lista -split '\s+') -notcontains $bucket) {
        EjecutarAws @('s3api','create-bucket','--bucket',$bucket,'--region',$region) | Out-Null
    }
    EjecutarAws @('s3api','put-bucket-versioning','--bucket',$bucket,
        '--versioning-configuration','Status=Enabled') | Out-Null
    EjecutarAws @('s3api','put-public-access-block','--bucket',$bucket,
        '--public-access-block-configuration',
        'BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true') | Out-Null
    $archivo = JsonTemporal @{
        Rules = @(@{ApplyServerSideEncryptionByDefault = @{SSEAlgorithm = 'AES256'}})
    }
    try {
        EjecutarAws @('s3api','put-bucket-encryption','--bucket',$bucket,
            '--server-side-encryption-configuration',('file://' + ($archivo -replace '\\','/'))) | Out-Null
    } finally { Remove-Item $archivo -ErrorAction SilentlyContinue }
}

Etapa 'Bucket etcd S3' {
    $cuenta = EjecutarAws @('sts','get-caller-identity','--query','Account','--output','text')
    $etcdBucket = "isc-obligatorio-etcd-$cuenta"
    $todos = EjecutarAws @('s3api','list-buckets','--query','Buckets[].Name','--output','text')
    if (@($todos -split '\s+') -notcontains $etcdBucket) {
        EjecutarAws @('s3api','create-bucket','--bucket',$etcdBucket,'--region',$region) | Out-Null
    }
    EjecutarAws @('s3api','put-public-access-block','--bucket',$etcdBucket,
        '--public-access-block-configuration',
        'BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true') | Out-Null
    $cifrado = JsonTemporal @{
        Rules = @(@{ApplyServerSideEncryptionByDefault = @{SSEAlgorithm = 'AES256'}})
    }
    $retencion = JsonTemporal @{
        Rules = @(@{ID='retencion-etcd';Status='Enabled';Filter=@{Prefix='snapshots/'};Expiration=@{Days=7}})
    }
    try {
        EjecutarAws @('s3api','put-bucket-encryption','--bucket',$etcdBucket,
            '--server-side-encryption-configuration',('file://' + ($cifrado -replace '\\','/'))) | Out-Null
        EjecutarAws @('s3api','put-bucket-lifecycle-configuration','--bucket',$etcdBucket,
            '--lifecycle-configuration',('file://' + ($retencion -replace '\\','/'))) | Out-Null
    } finally {
        Remove-Item $cifrado,$retencion -ErrorAction SilentlyContinue
    }
}

Etapa 'Terraform' {
    Push-Location $tf
    try {
        Tf @('init','-reconfigure',"-backend-config=bucket=$bucket",
            '-backend-config=key=infra/terraform.tfstate',"-backend-config=region=$region",'-input=false')
        Tf @('validate')

        Tf @('plan','-out=despliegue.tfplan','-input=false')
        $plan = (& terraform show -json despliegue.tfplan | Out-String) | ConvertFrom-Json
        if ($LASTEXITCODE -ne 0) { throw 'No se pudo leer el plan Terraform' }
        foreach ($r in $plan.resource_changes) {
            if ($r.change.actions -contains 'delete') {
                throw "Terraform intentaria eliminar o reemplazar $($r.address)"
            }
        }
        Tf @('apply','-input=false','despliegue.tfplan')
        $idsJson = & terraform output -json instancias_k3s
        if ($LASTEXITCODE -ne 0) { throw 'Error leyendo instancias_k3s' }
        $ids = ConvertFrom-Json -InputObject ($idsJson | Out-String)
        $script:instancias = @()
        foreach ($id in $ids) { $script:instancias += [string]$id }
        if ($instancias.Count -ne 3) { throw 'No se obtuvieron tres EC2' }
        $script:efs = (& terraform output -raw efs_id | Out-String).Trim()
        $script:url = (& terraform output -raw url_online_boutique | Out-String).Trim()
    } finally {
        Remove-Item 'despliegue.tfplan' -ErrorAction SilentlyContinue
        Pop-Location
    }
}

Etapa 'K3s' {
    $online = @()
    for ($i = 0; $i -lt 120; $i++) {
        $texto = EjecutarAws @('ssm','describe-instance-information','--region',$region,
            '--filters','Key=PingStatus,Values=Online',
            '--query','InstanceInformationList[].InstanceId','--output','text')
        $online = @($texto -split '\s+' | Where-Object { $_ -match '^i-[0-9a-f]+$' })
        if (@($instancias | Where-Object { $online -notcontains $_ }).Count -eq 0) { break }
        Start-Sleep 15
    }
    if (@($instancias | Where-Object { $online -notcontains $_ }).Count) {
        throw 'Las tres EC2 no estan Online en SSM'
    }

    foreach ($id in $instancias) {
        Write-Host "Verificando $id"
        Ssm $id @(
            'set -eu',
            'cloud-init status --wait >/dev/null 2>&1 || true',
            'if systemctl is-active --quiet k3s; then echo K3S_ACTIVO; exit 0; fi',
            'if test -x /usr/local/bin/k3s; then systemctl restart k3s >/dev/null 2>&1 || true; fi',
            'if systemctl is-active --quiet k3s; then echo K3S_RECUPERADO; exit 0; fi',
            'f=/var/lib/cloud/instance/scripts/part-001',
            'test -f "$f"',
            'sed -i "s/dnf install -y nfs-utils curl/dnf install -y nfs-utils/" "$f"',
            'sed -i "s/^set -euxo pipefail$/set -euo pipefail/" "$f"',
            'bash "$f" >/dev/null 2>&1 || { echo ERROR_INSTALACION_K3S; exit 1; }',
            'systemctl is-active --quiet k3s',
            'echo K3S_INSTALADO'
        ) | Out-Host
    }
    $estado = Ssm $instancias[0] @(
        'set -eu',
        'for i in $(seq 1 180); do n=$(kubectl get nodes --no-headers 2>/dev/null | wc -l); if [ "$n" -eq 3 ]; then break; fi; sleep 10; done',
        'test "$(kubectl get nodes --no-headers | wc -l)" -eq 3',
        'kubectl wait --for=condition=Ready node --all --timeout=900s',
        'kubectl get nodes -o wide'
    )
    Write-Host $estado
    if ($estado -notmatch 'Ready') { throw 'Los nodos K3s no estan Ready' }
}

Etapa 'Verificacion snapshots etcd' {
    $resultado = Ssm $instancias[0] @(
        'set -eu',
        'k3s etcd-snapshot save --name isc-validacion',
        'if /usr/local/sbin/isc-etcd-s3-sync.sh; then echo SNAPSHOT_S3_OK; else echo AVISO_SNAPSHOT_S3_NO_DISPONIBLE; fi'
    )
    Write-Host $resultado
    if ($resultado -notmatch 'SNAPSHOT_S3_OK') {
        Write-Warning 'K3s funciona, pero no se verifico la copia S3. Revisar permisos del LabRole.'
    }
}

Etapa 'Online Boutique' {
    $yaml = [IO.File]::ReadAllText((Join-Path $raiz 'kubernetes/app.yaml'))
    $memoria = New-Object IO.MemoryStream
    $gzip = [IO.Compression.GZipStream]::new($memoria,[IO.Compression.CompressionMode]::Compress,$true)
    $bytes = [Text.Encoding]::UTF8.GetBytes($yaml)
    $gzip.Write($bytes,0,$bytes.Length)
    $gzip.Dispose()
    $datos = [Convert]::ToBase64String($memoria.ToArray())
    $memoria.Dispose()
    $servidor = "$efs.efs.$region.amazonaws.com"
    Ssm $instancias[0] @(
        'set -eu',
        "printf '%s' '$datos' | base64 -d | gzip -d > /tmp/online-boutique.yaml",
        "sed -i 's/EFS_SERVER_PLACEHOLDER/$servidor/g' /tmp/online-boutique.yaml",
        'kubectl apply -f /tmp/online-boutique.yaml',
        'for d in adservice cartservice checkoutservice currencyservice emailservice frontend paymentservice productcatalogservice recommendationservice redis-cart shippingservice; do kubectl rollout status deployment/$d --timeout=900s; done',
        'kubectl get pods -o wide'
    ) | Out-Host
}

Etapa 'Redis y EFS' {
    Ssm $instancias[0] @(
        'set -eu',
        'kubectl wait --for=jsonpath="{.status.phase}"=Bound pvc/redis-data --timeout=120s',
        'kubectl exec deploy/redis-cart -- redis-cli ping | grep PONG',
        'kubectl exec deploy/redis-cart -- redis-cli CONFIG GET appendonly | grep -A1 appendonly | grep yes',
        'kubectl get pv redis-efs',
        'kubectl get hpa',
        'kubectl get pdb'
    ) | Out-Host
}

Etapa 'Monitoreo y backups' {
    $planes = EjecutarAws @('backup','list-backup-plans','--region',$region,
        '--query','BackupPlansList[].BackupPlanName','--output','text')
    $alarmas = EjecutarAws @('cloudwatch','describe-alarms','--region',$region,
        '--alarm-name-prefix','isc-obligatorio-','--query','MetricAlarms[].AlarmName','--output','text')
    $suscripciones = EjecutarAws @('sns','list-subscriptions','--region',$region,
        '--query','Subscriptions[].Endpoint','--output','text')
    if (@($planes -split '\s+') -notcontains 'isc-obligatorio-redis') { throw 'Falta AWS Backup' }
    if (@($alarmas -split '\s+' | Where-Object { $_ -match '^isc-obligatorio-' }).Count -lt 17) {
        throw 'Faltan alarmas CloudWatch (se esperan 17)'
    }
    $grupoLogs = EjecutarAws @('logs','describe-log-groups','--region',$region,
        '--log-group-name-prefix','/isc-obligatorio/k3s','--query','logGroups[].logGroupName','--output','text')
    if (@($grupoLogs -split '\s+') -notcontains '/isc-obligatorio/k3s') { throw 'Falta el grupo de CloudWatch Logs' }
    $panel = EjecutarAws @('cloudwatch','list-dashboards','--region',$region,
        '--dashboard-name-prefix','isc-obligatorio-panel','--query','DashboardEntries[].DashboardName','--output','text')
    if (@($panel -split '\s+') -notcontains 'isc-obligatorio-panel') { throw 'Falta el dashboard de CloudWatch' }
    if (@($suscripciones -split '\s+') -notcontains $mail) { throw 'Falta suscripcion SNS' }
}

Etapa 'Validacion final' {
    $grupo = EjecutarAws @('elbv2','describe-target-groups','--region',$region,
        '--names','isc-obligatorio-web','--query','TargetGroups[0].TargetGroupArn','--output','text')
    $saludable = $false
    for ($i = 0; $i -lt 60; $i++) {
        $salud = EjecutarAws @('elbv2','describe-target-health','--region',$region,
            '--target-group-arn',$grupo,
            '--query','TargetHealthDescriptions[].TargetHealth.State','--output','text')
        if (@($salud -split '\s+' | Where-Object { $_ -eq 'healthy' }).Count -ge 2) {
            $saludable = $true
            break
        }
        Start-Sleep 15
    }
    if (-not $saludable) { throw 'ALB sin dos targets saludables' }
    $ok = $false
    for ($i = 0; $i -lt 12; $i++) {
        try {
            if ((Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 30).StatusCode -eq 200) {
                $ok = $true
                break
            }
        } catch {}
        Start-Sleep 10
    }
    if (-not $ok) { throw 'Online Boutique no responde HTTP 200' }
}

Write-Host "`nONLINE BOUTIQUE: $url" -ForegroundColor Green
