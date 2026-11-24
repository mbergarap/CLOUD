# Operación

## Despliegue

```powershell
copy config.example.psd1 config.psd1   # OPCIONAL: sin este archivo, el script pide el correo y calcula el bucket
.\validar.ps1
.\desplegar.ps1
```

`desplegar.ps1` crea con AWS CLI el bucket de estado y el de snapshots de etcd (cifrados, sin acceso público), ejecuta `init`/`validate`/`plan`/`apply`, espera a K3s, aplica `kubernetes/app.yaml`, verifica Redis/EFS, monitoreo, logs y backups, y comprueba que el ALB responda 200. **Aborta si el plan incluye eliminaciones o reemplazos.**

## Variables de Terraform (`terraform/variables.tf`)

| Variable | Defecto | Descripción |
|---|---|---|
| `alerta_mail` | (obligatoria) | Correo de alertas (el script la toma de `config.psd1` o la pide) |
| `nombre_proyecto` | `isc-obligatorio` | Prefijo de nombres |
| `region` | `us-east-1` | Región |
| `cidr_vpc` | `10.80.0.0/16` | CIDR de la VPC |
| `tipo_instancia` | `t3.medium` | Tipo de EC2 |
| `version_k3s` | `v1.37.2+k3s1` | Versión de K3s (vacío = última) |
| `dias_retencion_logs` | `14` | Retención de logs |
| `habilitar_recuperacion_ec2` | `false` | Recuperación automática de EC2 | (activar solo si AWS Academy lo permite)

> `desplegar.ps1` y las alarmas usan el prefijo `isc-obligatorio`: si se cambia `nombre_proyecto`, ajustar también el script.

## Ya existe un despliegue anterior

Esta versión cambia los Security Groups a reglas independientes. Sobre una infraestructura creada con la versión anterior, el plan incluiría eliminaciones de reglas y `desplegar.ps1` lo bloqueará. Opciones: desplegar en una cuenta limpia (recomendado) o revisar el plan a mano. Los buckets de estado y de etcd no forman parte del estado de Terraform, por lo que no se ven afectados.

## Comandos útiles

```bash
aws ssm start-session --target <id-instancia>   # acceso sin SSH
sudo k3s kubectl get nodes,pods -o wide
sudo k3s kubectl get hpa,pdb
```

## Integración continua

`.github/workflows/terraform.yml` ejecuta `terraform fmt -check` y `terraform validate` en cada push y pull request.
