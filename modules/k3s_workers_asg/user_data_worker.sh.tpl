#!/bin/bash
set -euo pipefail
exec > >(tee /var/log/k3s-worker-init.log) 2>&1

# Espera a que el server publique el token en SSM
TOKEN=""
for i in $(seq 1 60); do
  TOKEN=$(aws ssm get-parameter --region ${region} --name ${token_param} \
          --with-decryption --query Parameter.Value --output text 2>/dev/null || true)
  [ -n "$TOKEN" ] && break
  echo "Esperando token en SSM ($i/60)..."; sleep 10
done
[ -n "$TOKEN" ] || { echo "No se obtuvo el token"; exit 1; }

# Espera a que la API del server responda
for i in $(seq 1 60); do
  curl -sk --max-time 3 https://${server_ip}:6443/ping >/dev/null && break || sleep 10
done

export K3S_URL="https://${server_ip}:6443"
export K3S_TOKEN="$TOKEN"
%{ if k3s_version != "" ~}
export INSTALL_K3S_VERSION="${k3s_version}"
%{ endif ~}
curl -sfL https://get.k3s.io | sh -s - agent
