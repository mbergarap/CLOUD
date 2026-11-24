# Respaldos y recuperación

## Qué se respalda

| Dato | Mecanismo | Frecuencia | Retención |
|---|---|---|---|
| Datos de Redis (EFS) | AWS Backup (vault + plan + selección, en `modules/storage`) | Diario 03:00 UTC | 7 días |
| Estado del clúster (etcd) | Snapshots locales de K3s en cada nodo, copiados a S3 por un timer de systemd (`aws s3 sync`, SSE-S3). El bucket lo crea `desplegar.ps1` con AWS CLI | Snapshot cada 12 h; copia a S3 cada 12 h | Local: 14 snapshots; S3: 7 días (ciclo de vida del bucket) |
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
# 1. traer el snapshot desde S3 (o usar uno local en /var/lib/rancher/k3s/server/db/snapshots)
aws s3 cp s3://isc-obligatorio-etcd-<cuenta>/snapshots/<nodo>/<archivo> /tmp/snapshot.db
# 2. restaurar
k3s server --cluster-reset --cluster-reset-restore-path=/tmp/snapshot.db
```

Los otros dos servidores se reincorporan borrando `/var/lib/rancher/k3s/server/db` y reiniciando el servicio.

## Limitaciones

- No hay restauración automática.
- La copia de snapshots a S3 es de mejor esfuerzo: si `LabRole` no tiene permisos, K3s sigue funcionando y conserva los snapshots locales. Verificar que lleguen archivos a `s3://isc-obligatorio-etcd-<cuenta>/snapshots/`.
- Las pruebas de AWS Backup y de snapshots de etcd dependen de los permisos de `LabRole` en AWS Academy.
