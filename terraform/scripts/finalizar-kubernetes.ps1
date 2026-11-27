
#Requires -Version 5.1

# RECIBE LOS PARAMETROS NECESARIOS PARA CONFIGURAR Y VALIDAR EL DESPLIEGUE DE ONLINE BOUTIQUE.
param(
    [Parameter(Mandatory=$true)][string]$Region,
    [Parameter(Mandatory=$true)][string]$NombreProyecto,
    [Parameter(Mandatory=$true)][string]$Instancias,
    [Parameter(Mandatory=$true)][string]$EfsId,
    [Parameter(Mandatory=$true)][string]$Url,
    [Parameter(Mandatory=$true)][string]$Correo,
    [Parameter(Mandatory=$true)][string]$ManifestPath,
    [Parameter(Mandatory=$true)][string]$ExpectedAccount
)
$ErrorActionPreference = 'Stop'

# VALIDA LOS IDENTIFICADORES DE LAS TRES INSTANCIAS EC2 Y LA EXISTENCIA DEL MANIFIESTO KUBERNETES.
$ids = @($Instancias -split ',' | Where-Object { $_ -match '^i-[0-9a-f]+$' })
if ($ids.Count -ne 3) { throw 'Se esperaban tres IDs de instancias EC2.' }
if (-not (Test-Path -LiteralPath $ManifestPath)) { throw "No existe el manifiesto: $ManifestPath" }

# EJECUTA COMANDOS DE AWS CLI Y DETIENE EL PROCESO SI ALGUNO FALLA.
function Invoke-AwsCli([string[]]$ArgsList) {
    $s = & aws @ArgsList 2>&1
    if ($LASTEXITCODE -ne 0) { throw "AWS CLI ($($ArgsList[0..1] -join ' ')): $($s | Out-String)" }
    return ($s | Out-String).Trim()
}

# GENERA ARCHIVOS JSON TEMPORALES PARA ENVIAR PARAMETROS A AWS SYSTEMS MANAGER.
function JsonTemporal($value) {
    $path = Join-Path $env:TEMP ("isc-" + [guid]::NewGuid().ToString('N') + '.json')
    [IO.File]::WriteAllText($path, ($value | ConvertTo-Json -Depth 8 -Compress), [Text.UTF8Encoding]::new($false))
    return $path
}

# EJECUTA COMANDOS REMOTOS EN LAS INSTANCIAS EC2 MEDIANTE SSM Y VERIFICA SU RESULTADO.
function Ssm([string]$instance, [string[]]$commands) {
    $path = JsonTemporal @{ commands = $commands; executionTimeout = @('3600') }
    try {
        $id = Invoke-AwsCli @('ssm','send-command','--region',$Region,'--instance-ids',$instance,
            '--document-name','AWS-RunShellScript','--parameters',('file://' + ($path -replace '\\','/')),
            '--query','Command.CommandId','--output','text')
    } finally { Remove-Item $path -ErrorAction SilentlyContinue }
    for ($i=0; $i -lt 240; $i++) {
        Start-Sleep -Seconds 15
        try {
            $response = (Invoke-AwsCli @('ssm','get-command-invocation','--region',$Region,
                '--command-id',$id,'--instance-id',$instance,'--output','json')) | ConvertFrom-Json
        } catch { continue }
        if ($response.Status -eq 'Success') {
            Write-Host $response.StandardOutputContent
            return
        }
        if ($response.Status -in @('Failed','Cancelled','TimedOut','Cancelling')) {
            throw "SSM $instance : $($response.Status) $($response.StandardOutputContent) $($response.StandardErrorContent)"
        }
    }
    throw "SSM sin respuesta: $id ($instance)"
}

# VERIFICA QUE AWS CLI UTILICE LA MISMA CUENTA AWS QUE EL PROVEEDOR DE TERRAFORM.
$activeAccount = Invoke-AwsCli @('sts','get-caller-identity','--query','Account','--output','text')
if ($activeAccount -ne $ExpectedAccount) { throw 'La cuenta AWS CLI no coincide con la cuenta del proveedor Terraform.' }

# ESPERA QUE LAS TRES INSTANCIAS EC2 ESTEN DISPONIBLES EN AWS SYSTEMS MANAGER.
$online = @()
for ($i=0; $i -lt 120; $i++) {
    $text = Invoke-AwsCli @('ssm','describe-instance-information','--region',$Region,
        '--filters','Key=PingStatus,Values=Online','--query','InstanceInformationList[].InstanceId','--output','text')
    $online = @($text -split '\s+' | Where-Object { $_ -match '^i-[0-9a-f]+$' })
    if (@($ids | Where-Object { $online -notcontains $_ }).Count -eq 0) { break }
    Start-Sleep -Seconds 15
}
if (@($ids | Where-Object { $online -notcontains $_ }).Count -ne 0) { throw 'No estan las tres instancias Online en SSM.' }

# VERIFICA K3S EN CADA INSTANCIA E INTENTA RECUPERAR SU INSTALACION SI NO ESTA ACTIVO.
foreach ($id in $ids) {
    Write-Host "Comprobando K3s: $id"
    Ssm $id @(
        'set -eu',
        'cloud-init status --wait >/dev/null 2>&1 || true',
        'if systemctl is-active --quiet k3s; then echo K3S_ACTIVO; exit 0; fi',
        'if test -x /usr/local/bin/k3s; then systemctl restart k3s >/dev/null 2>&1 || true; fi',
        'if systemctl is-active --quiet k3s; then echo K3S_RECUPERADO; exit 0; fi',
        'f=/var/lib/cloud/instance/scripts/part-001',
        'test -f "$f"',
        'bash "$f" >/dev/null 2>&1 || { echo ERROR_INSTALACION_K3S; exit 1; }',
        'systemctl is-active --quiet k3s',
        'echo K3S_INSTALADO'
    )
}

# ESPERA QUE LOS TRES NODOS DE K3S SE REGISTREN EN EL CLUSTER Y ALCANCEN EL ESTADO READY.
Ssm $ids[0] @(
    'set -eu',
    'for i in $(seq 1 180); do n=$(kubectl get nodes --no-headers 2>/dev/null | wc -l); if [ "$n" -eq 3 ]; then break; fi; sleep 10; done',
    'test "$(kubectl get nodes --no-headers | wc -l)" -eq 3',
    'kubectl wait --for=condition=Ready node --all --timeout=900s',
    'kubectl get nodes -o wide'
)

# IDENTIFICA LA REGION Y ZONA DE DISPONIBILIDAD DE CADA NODO Y AGREGA SUS ETIQUETAS A KUBERNETES.
foreach ($id in $ids) {
    Ssm $id @(
        'set -eu',
        'TOKEN=$(curl -fsS -X PUT -H "X-aws-ec2-metadata-token-ttl-seconds: 60" http://169.254.169.254/latest/api/token)',
        'AZ=$(curl -fsS -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)',
        'REGION=$(curl -fsS -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region)',
        'test -n "$AZ" && test -n "$REGION"',
        'kubectl label node "$(hostname -f)" "topology.kubernetes.io/zone=$AZ" "topology.kubernetes.io/region=$REGION" --overwrite'
    )
}

# GENERA UN SNAPSHOT DE VALIDACION DE ETCD E INTENTA SINCRONIZARLO CON EL BUCKET S3.
Ssm $ids[0] @(
    'set -eu',
    'k3s etcd-snapshot save --name isc-validacion',
    'if /usr/local/sbin/isc-etcd-s3-sync.sh; then echo SNAPSHOT_S3_OK; else echo AVISO_SNAPSHOT_S3_NO_DISPONIBLE; fi'
)

# COMPRIME Y CODIFICA EL MANIFIESTO KUBERNETES PARA TRANSFERIRLO AL SERVIDOR PRINCIPAL MEDIANTE SSM.
$yaml = [IO.File]::ReadAllText($ManifestPath)
$memory = New-Object IO.MemoryStream
$gzip = [IO.Compression.GZipStream]::new($memory,[IO.Compression.CompressionMode]::Compress,$true)
$bytes = [Text.Encoding]::UTF8.GetBytes($yaml)
$gzip.Write($bytes,0,$bytes.Length)
$gzip.Dispose()
$encoded = [Convert]::ToBase64String($memory.ToArray())
$memory.Dispose()

# CONSTRUYE EL NOMBRE DNS DEL SISTEMA EFS UTILIZADO PARA EL ALMACENAMIENTO PERSISTENTE.
$efsDns = "$EfsId.efs.$Region.amazonaws.com"

# TRANSFIERE EL MANIFIESTO, CONFIGURA EL ACCESO A EFS Y DESPLIEGA ONLINE BOUTIQUE EN KUBERNETES.
Ssm $ids[0] @(
    'set -eu',
    "printf '%s' '$encoded' | base64 -d | gzip -d > /tmp/online-boutique.yaml",
    "sed -i 's/EFS_SERVER_PLACEHOLDER/$efsDns/g' /tmp/online-boutique.yaml",
    'kubectl apply -f /tmp/online-boutique.yaml',
    'for d in adservice cartservice checkoutservice currencyservice emailservice frontend paymentservice productcatalogservice recommendationservice redis-cart shippingservice; do kubectl rollout status deployment/$d --timeout=900s; done',
    'kubectl get deployments'
)

# VALIDA QUE LOS MICROSERVICIOS TENGAN ENTRE DOS Y CUATRO REPLICAS LISTAS Y DISTRIBUIDAS EN AL MENOS DOS ZONAS.
Ssm $ids[0] @(
    'set -eu',
    'for d in adservice cartservice checkoutservice currencyservice emailservice frontend paymentservice productcatalogservice recommendationservice shippingservice; do',
    '  kubectl rollout status deployment/"$d" --timeout=180s',
    '  deseadas=$(kubectl get deployment "$d" -o jsonpath="{.spec.replicas}")',
    '  listas=$(kubectl get deployment "$d" -o jsonpath="{.status.readyReplicas}")',
    '  test "$deseadas" -ge 2 && test "$deseadas" -le 4 || { echo "ERROR: $d replicas fuera de rango"; exit 1; }',
    '  test "$listas" = "$deseadas" || { echo "ERROR: $d tiene $listas/$deseadas replicas listas"; exit 1; }',
    '  nodes=$(kubectl get pods -l "app=$d" -o custom-columns="READY:.status.containerStatuses[0].ready,NODE:.spec.nodeName" --no-headers | awk ''$1=="true" {print $2}'')',
    '  count=$(printf "%s\n" "$nodes" | sed "/^$/d" | wc -l)',
    '  test "$count" -eq "$deseadas" || { echo "ERROR: $d tiene $count pods listos"; exit 1; }',
    '  zones=""',
    '  for node in $nodes; do',
    '    zone=$(kubectl get node "$node" -o jsonpath="{.metadata.labels.topology\.kubernetes\.io/zone}")',
    '    test -n "$zone" && test "$zone" != "<none>" || { echo "ERROR: nodo $node sin zona AWS"; exit 1; }',
    '    zones="$zones $zone"',
    '  done',
    '  distintas=$(printf "%s\n" $zones | sort -u | wc -l)',
    '  test "$distintas" -ge 2 || { echo "ERROR: $d no esta distribuido entre zonas"; exit 1; }',
    '  echo "$d OK: $listas/$deseadas replicas, $distintas zonas"',
    'done'
)

# COMPRUEBA EL ALMACENAMIENTO PERSISTENTE DE REDIS, SU DISPONIBILIDAD Y LAS POLITICAS DE ESCALADO Y DISPONIBILIDAD.
Ssm $ids[0] @(
    'set -eu',
    'kubectl wait --for=jsonpath="{.status.phase}"=Bound pvc/redis-data --timeout=120s',
    'kubectl exec deploy/redis-cart -- redis-cli ping | grep PONG',
    'kubectl exec deploy/redis-cart -- redis-cli CONFIG GET appendonly | grep -A1 appendonly | grep yes',
    'test "$(kubectl get hpa --no-headers | wc -l)" -eq 6',
    'test "$(kubectl get pdb --no-headers | wc -l)" -eq 10',
    'kubectl get pv redis-efs',
    'kubectl get hpa',
    'kubectl get pdb'
)

# CONSULTA LOS RECURSOS DE AWS BACKUP, CLOUDWATCH Y SNS PARA VALIDAR QUE EL MONITOREO ESTE CONFIGURADO.
$plans = Invoke-AwsCli @('backup','list-backup-plans','--region',$Region,'--query','BackupPlansList[].BackupPlanName','--output','text')
$alarms = Invoke-AwsCli @('cloudwatch','describe-alarms','--region',$Region,'--alarm-name-prefix',"$NombreProyecto-",'--query','MetricAlarms[].AlarmName','--output','text')
$subscriptions = Invoke-AwsCli @('sns','list-subscriptions','--region',$Region,'--query','Subscriptions[].Endpoint','--output','text')
$logs = Invoke-AwsCli @('logs','describe-log-groups','--region',$Region,'--log-group-name-prefix',"/$NombreProyecto/k3s",'--query','logGroups[].logGroupName','--output','text')
$dashboards = Invoke-AwsCli @('cloudwatch','list-dashboards','--region',$Region,'--dashboard-name-prefix',"$NombreProyecto-panel",'--query','DashboardEntries[].DashboardName','--output','text')

# COMPRUEBA LA EXISTENCIA DEL PLAN DE BACKUP, LAS ALARMAS, LA SUSCRIPCION SNS, LOS LOGS Y EL DASHBOARD.
if (@($plans -split '\s+') -notcontains "$NombreProyecto-redis") { throw 'Falta plan AWS Backup.' }
if (@($alarms -split '\s+' | Where-Object { $_ -like "$NombreProyecto-*" }).Count -lt 17) { throw 'Faltan alarmas CloudWatch.' }
if (@($subscriptions -split '\s+') -notcontains $Correo) { throw 'Falta suscripcion SNS.' }
if (@($logs -split '\s+') -notcontains "/$NombreProyecto/k3s") { throw 'Falta el grupo CloudWatch Logs.' }
if (@($dashboards -split '\s+') -notcontains "$NombreProyecto-panel") { throw 'Falta el dashboard CloudWatch.' }

# IDENTIFICA EL TARGET GROUP Y ESPERA QUE EL ALB TENGA AL MENOS DOS DESTINOS SALUDABLES.
$tg = Invoke-AwsCli @('elbv2','describe-target-groups','--region',$Region,'--names',"$NombreProyecto-web",'--query','TargetGroups[0].TargetGroupArn','--output','text')
$okTargets = $false
for ($i=0; $i -lt 60; $i++) {
    $states = Invoke-AwsCli @('elbv2','describe-target-health','--region',$Region,'--target-group-arn',$tg,'--query','TargetHealthDescriptions[].TargetHealth.State','--output','text')
    if (@($states -split '\s+' | Where-Object { $_ -eq 'healthy' }).Count -ge 2) { $okTargets = $true; break }
    Start-Sleep -Seconds 15
}
if (-not $okTargets) { throw 'El ALB no tiene dos targets saludables.' }

# VERIFICA QUE ONLINE BOUTIQUE SEA ACCESIBLE DESDE EL ALB Y DEVUELVA UNA RESPUESTA HTTP 200.
$httpOK = $false
for ($i=0; $i -lt 12; $i++) {
    try {
        if ((Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 30).StatusCode -eq 200) {
            $httpOK = $true; break
        }
    } catch {}
    Start-Sleep -Seconds 10
}
if (-not $httpOK) { throw 'Online Boutique no devuelve HTTP 200.' }

# CONFIRMA QUE EL DESPLIEGUE FINALIZO Y ONLINE BOUTIQUE ESTA OPERATIVA.
Write-Host "ONLINE BOUTIQUE OPERATIVA: $Url"
