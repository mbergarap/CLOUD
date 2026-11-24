# Respaldos y recuperación

## Qué se respalda

| Dato | Mecanismo | Frecuencia | Retención |
|---|---|---|---|
| Datos de Redis (EFS) | AWS Backup (vault + plan + selección, en `modules/storage`) | Diario 03:00 UTC | 7 días |
| Estado del clúster (etcd) | Snapshots de K3s a S3 (bucket cifrado, sin acceso público, administrado por Terraform) | Cada 12 h | 7 días (ciclo de vida del bucket) |
| Estado de Terraform | Bucket S3 con versionado | Cada `apply` | Versiones previas |

## Recuperación

> Los comandos son el procedimiento documentado por AWS y K3s. **Aún no se ejecutó una restauración completa**; registrar el resultado en [PRUEBAS.md](PRUEBAS.md).

**EFS (Redis):**

```bash
aws backup list-recovery-points-by-backup-vault --backup-vault-name isc-obligatorio-redis
aws backup start-restore-job --recovery-point-arn <arn> --iam-role-arn <arn-LabRole> \
  --metadata file://restore-metadata.json
```

Se restaura a un EFS nuevo; luego se apunta el PV `redis-efs` al nuevo sistema de archivos.

**etcd:**

```bash
# en un nodo K3s, con k3s detenido
k3s server --cluster-reset --cluster-reset-restore-path=snapshots/<archivo> \
  --etcd-s3 --etcd-s3-bucket <bucket> --etcd-s3-region us-east-1
```

Los otros dos servidores se reincorporan borrando `/var/lib/rancher/k3s/server/db` y reiniciando el servicio.

## Limitaciones

- No hay restauración automática.
- Las pruebas de AWS Backup y de snapshots de etcd dependen de los permisos de `LabRole` en AWS Academy.
