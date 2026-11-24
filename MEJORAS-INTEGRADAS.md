# Integracion del paquete de mejoras

**Incluido:** SG como reglas Terraform independientes; CloudWatch Logs y agente opcional; alarmas adicionales, dashboard, version K3s fija; replicas/HPA/PDB de microservicios; scripts de carga y prueba de fallo (no se ejecutan automaticamente); documentacion modular; diagrama; CI Terraform.

**No integrado:** bucket S3 de etcd administrado por Terraform; bucket de logs ALB via Terraform; recuperacion EC2 habilitada por defecto. Estas opciones tienen riesgo con AWS Academy y el error SCP ya observado.

**Adicional:** la transferencia de snapshots etcd a S3 es `best effort`, con timer de systemd; si no hay permisos se genera un aviso sin impedir el inicio de Kubernetes.

**Limite:** esta entrega se reviso estaticamente; no se probó en AWS ni se garantiza aplicacion incremental sobre un estado Terraform antiguo con distinta estructura de Security Groups.
