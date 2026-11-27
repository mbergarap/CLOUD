# ESPERA A QUE K3S Y ONLINE BOUTIQUE ESTEN DISPONIBLES.
resource "aws_ssm_association" "verificar_kubernetes" {
  name                             = "AWS-RunShellScript"
  association_name                 = "${var.nombre_proyecto}-verificar-kubernetes"
  wait_for_success_timeout_seconds = 3600

  # EJECUTA LA VERIFICACION EN EL SERVIDOR PRINCIPAL.
  targets {
    key    = "InstanceIds"
    values = [module.compute.instance_ids[0]]
  }

  # GENERA EL SCRIPT CON SALTOS DE LINEA LINUX.
  parameters = {
    executionTimeout = "3600"

    commands = join("\n", [
      "#!/bin/bash",
      "set -euo pipefail",
      "cloud-init status --wait",
      "test \"$(cloud-init status)\" = \"status: done\"",
      "for INTENTO in $(seq 1 180); do",
      "  NODOS=$(k3s kubectl get nodes --no-headers 2>/dev/null | awk '$2 == \"Ready\" {n++} END {print n+0}' || true)",
      "  FRONTEND=$(k3s kubectl get deployment frontend -o jsonpath='{.status.readyReplicas}' 2>/dev/null || true)",
      "  HTTP=000",
      "  if [ \"$NODOS\" = \"3\" ] && [ \"$FRONTEND\" = \"2\" ]; then",
      "    HTTP=$(curl -sS --max-time 10 -o /dev/null -w '%%{http_code}' 'http://${module.compute.alb_dns}/' || true)",
      "  fi",
      "  if [ \"$NODOS\" = \"3\" ] && [ \"$FRONTEND\" = \"2\" ] && [ \"$HTTP\" = \"200\" ]; then",
      "    echo 'K3S Y ONLINE BOUTIQUE DISPONIBLES. HTTP 200.'",
      "    exit 0",
      "  fi",
      "  sleep 10",
      "done",
      "echo 'ERROR: ONLINE BOUTIQUE NO ESTA DISPONIBLE.' >&2",
      "exit 1",
    ])
  }

  depends_on = [
    module.compute
  ]
}