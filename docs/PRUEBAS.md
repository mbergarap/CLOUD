# Pruebas

Este documento es el registro de evidencia. **Completar con las salidas reales** de cada prueba; las secciones vacías son pruebas pendientes.

## Verificaciones del despliegue

`desplegar.ps1` comprueba automáticamente: 3 EC2 en SSM, 3 nodos `Ready`, microservicios disponibles, Redis `PONG` con AOF, PVC enlazado, HPA/PDB creados, 17 alarmas, grupo de logs, dashboard, plan de AWS Backup, suscripción SNS, ≥ 2 targets sanos y HTTP 200.

## 1. Prueba de carga

```powershell
.\pruebas\prueba-carga.ps1 -Pico 150
# en otra terminal, dentro de un nodo: kubectl get hpa -w
```

Perfil (`pruebas/carga.k6.js`): 6 min, calentamiento, subida y pico sostenido. Umbrales: errores < 1 % y p95 < 2 s.

| Dato | Resultado |
|---|---|
| Fecha y pico de usuarios virtuales | |
| Solicitudes totales / por segundo | |
| Errores (%) | |
| p95 de latencia | |
| Réplicas máximas alcanzadas por el HPA (frontend) | |
| Alarmas que se dispararon | |

## 2. Falla de una instancia / una AZ

```powershell
.\pruebas\prueba-fallo-instancia.ps1 -Indice 1 -DuracionMinutos 5
```

Detiene una EC2 (equivale a perder una AZ), mide HTTP y targets sanos cada 5 s, la vuelve a iniciar y genera `resultado-fallo-instancia.csv`.

| Dato | Resultado |
|---|---|
| Disponibilidad HTTP durante la falla | |
| Mínimo de targets sanos | |
| Tiempo hasta que el ALB retiró el target | |
| Tiempo hasta recuperar 3 targets sanos | |
| ¿Llegó la alarma por correo? | |

## 3. Falla de un pod

```bash
kubectl delete pod -l app=frontend --wait=false
kubectl get pods -w
```

| Dato | Resultado |
|---|---|
| Tiempo de recuperación | |
| ¿Hubo errores visibles? | |

## 4. Respaldos

| Prueba | Resultado |
|---|---|
| Existe un recovery point de AWS Backup (EFS) | |
| Se restauró el recovery point | |
| Llegan snapshots de etcd al bucket S3 | |
| Se probó la restauración de etcd | |
| Llegan logs al grupo `/isc-obligatorio/k3s` y al bucket de logs del ALB | |
