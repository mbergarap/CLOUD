# Seguridad de red

Todas las reglas están en `terraform/modules/security/main.tf` como recursos `aws_vpc_security_group_*_rule` independientes. Los Security Groups **no tienen reglas en línea ni `ignore_changes`**, de modo que Terraform detecta y corrige cualquier cambio manual.

## Reglas

| Security Group | Sentido | Origen / destino | Protocolo / puerto | Motivo |
|---|---|---|---|---|
| ALB | Entrada | Internet `0.0.0.0/0` | TCP 80 | Acceso público a la tienda |
| ALB | Salida | SG K3s | TCP 30080 | Reenviar al NodePort (solo a los nodos) |
| K3s | Entrada | SG ALB | TCP 30080 | Tráfico del balanceador |
| K3s | Entrada | SG K3s | TCP 6443 | API de Kubernetes |
| K3s | Entrada | SG K3s | TCP 2379–2380 | etcd |
| K3s | Entrada | SG K3s | TCP 10250 | Kubelet |
| K3s | Entrada | SG K3s | UDP 8472 | Flannel VXLAN |
| K3s | Salida | SG K3s | los 4 puertos anteriores | Comunicación entre nodos |
| K3s | Salida | `0.0.0.0/0` | TCP 443 | Imágenes, instalación de K3s, S3, SSM, CloudWatch |
| K3s | Salida | `0.0.0.0/0` | TCP 80 | Repositorios del sistema operativo |
| K3s | Salida | CIDR de la VPC | TCP/UDP 53 | DNS |
| K3s | Salida | SG EFS | TCP 2049 | NFS |
| EFS | Entrada | SG K3s | TCP 2049 | NFS desde los nodos |
| EFS | Salida | — | — | Sin reglas: las respuestas viajan por la conexión ya establecida |

## Medidas

- Nodos solo en subredes privadas, sin IP pública; no hay bastion ni SSH (puerto 22 cerrado). La administración usa SSM con `LabInstanceProfile`.
- Los puertos internos de K3s solo aceptan tráfico del propio Security Group.
- IMDSv2 obligatorio en las EC2 (`http_tokens = required`).
- EBS, EFS y los buckets S3 cifrados; buckets con bloqueo de acceso público.
- El estado de Terraform es local y contiene el token de K3s: se mantiene fuera de Git (`.gitignore`) y en una ubicación protegida.

## Limitaciones

- El tráfico a la tienda es HTTP (sin TLS): la cuenta de laboratorio no tiene dominio.
- La salida 443 a Internet es necesaria para descargar imágenes y K3s; en producción se reduciría con VPC endpoints y un registro privado.
- `LabInstanceProfile` es un rol amplio impuesto por AWS Academy; en producción se usaría un rol de mínimo privilegio.
