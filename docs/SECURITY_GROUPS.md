# Security Groups (completar con los nombres reales de tu Terraform)

| SG | Direccion | Puerto/Proto | Origen/Destino | Motivo |
|---|---|---|---|---|
| alb-sg | ingress | 80/tcp | 0.0.0.0/0 | Trafico publico HTTP |
| alb-sg | egress | 30080/tcp | k3s-sg | Hacia NodePort del frontend |
| k3s-sg | ingress | 30080/tcp | alb-sg | Trafico del ALB |
| k3s-sg | ingress | 6443/tcp | k3s-sg | API server (workers -> server) |
| k3s-sg | ingress | 8472/udp | k3s-sg | Flannel VXLAN |
| k3s-sg | ingress | 10250/tcp | k3s-sg | Kubelet |
| k3s-sg | ingress | 22/tcp | bastion-sg | SSH (eliminable si usan SSM) |
| rds-sg | ingress | 5432/tcp | k3s-sg | PostgreSQL |
| redis-sg | ingress | 6379/tcp | k3s-sg | ElastiCache |

Revisar tambien los egress: lo ideal es no dejar `0.0.0.0/0` salvo en los nodos (via NAT).
