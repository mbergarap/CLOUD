# Operación

## Despliegue

```powershell
copy config.example.psd1 config.psd1   # completar alerta_mail y nombre_bucket
.\validar.ps1
.\desplegar.ps1
```

`desplegar.ps1` crea el backend S3, ejecuta `init`/`validate`/`plan`/`apply`, espera a K3s, aplica `kubernetes/app.yaml`, verifica Redis/EFS, monitoreo, logs y backups, y comprueba que el ALB responda 200. **Aborta si el plan incluye eliminaciones o reemplazos.**

## Variables de Terraform (`terraform/variables.tf`)

| Variable | Defecto | Descripción |
|---|---|---|
| `alerta_mail` | (obligatoria) | Correo de alertas (la pasa el script desde `config.psd1`) |
| `nombre_proyecto` | `isc-obligatorio` | Prefijo de nombres |
| `region` | `us-east-1` | Región |
| `cidr_vpc` | `10.80.0.0/16` | CIDR de la VPC |
| `tipo_instancia` | `t3.medium` | Tipo de EC2 |
| `version_k3s` | `v1.37.2+k3s1` | Versión de K3s (vacío = última) |
| `dias_retencion_logs` | `14` | Retención de logs |
| `habilitar_logs_alb` | `true` | Logs de acceso del ALB en S3 |
| `habilitar_recuperacion_ec2` | `true` | Recuperación automática de EC2 |

> `desplegar.ps1` y las alarmas usan el prefijo `isc-obligatorio`: si se cambia `nombre_proyecto`, ajustar también el script.

## Ya existe un despliegue anterior

Esta versión cambia los Security Groups a reglas independientes. Sobre una infraestructura creada con la versión anterior, el plan incluiría eliminaciones de reglas y `desplegar.ps1` lo bloqueará. Opciones: desplegar en una cuenta limpia (recomendado) o revisar el plan a mano. El bucket de etcd, si ya existía, se importa automáticamente al estado.

## Comandos útiles

```bash
aws ssm start-session --target <id-instancia>   # acceso sin SSH
sudo k3s kubectl get nodes,pods -o wide
sudo k3s kubectl get hpa,pdb
```

## Integración continua

`.github/workflows/terraform.yml` ejecuta `terraform fmt -check` y `terraform validate` en cada push y pull request.
