#!/usr/bin/env bash
set -euo pipefail

# Levanta el entorno local completo: cluster k3d + Argo CD + los 2 microservicios.
# Duracion aproximada la primera vez: 3-5 min (descarga de imagenes de k3s y Argo CD).

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CLUSTER="microservicios-devops"
ARGOCD_NS="argocd"
APPS_NS="microservicios"

echo "==> [1/6] Creando el cluster k3d '${CLUSTER}' (si no existe)"
if k3d cluster list "${CLUSTER}" >/dev/null 2>&1; then
  echo "    Ya existe, se omite la creacion."
else
  k3d cluster create --config "${ROOT}/k3d/k3d-config.yaml"
fi

echo "==> [2/6] Esperando a que los nodos esten Ready"
kubectl wait --for=condition=Ready nodes --all --timeout=120s

echo "==> [3/6] Instalando Argo CD con Helm"
helm repo add argo https://argoproj.github.io/argo-helm >/dev/null 2>&1 || true
helm repo update >/dev/null
helm upgrade --install argocd argo/argo-cd \
  --namespace "${ARGOCD_NS}" --create-namespace \
  -f "${ROOT}/k3d/argocd/values.yaml" \
  --wait --timeout 5m

echo "==> [4/6] Esperando el rollout de argocd-server"
kubectl -n "${ARGOCD_NS}" rollout status deploy/argocd-server --timeout=180s

echo "==> [5/6] Registrando las Application de Argo CD y el Ingress"
kubectl create namespace "${APPS_NS}" --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n "${ARGOCD_NS}" -f "${ROOT}/k3d/argocd/apps/"
kubectl apply -f "${ROOT}/k3d/manifests/ingress.yaml"

echo "==> [6/6] Entorno listo"
PASS="$(kubectl -n "${ARGOCD_NS}" get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)"
cat <<EOF

  Argo CD UI        : http://argocd.localtest.me:8080   (usuario: admin  /  password: ${PASS})
                      alternativa: kubectl -n argocd port-forward svc/argocd-server 8081:80

  servicio-usuarios : http://usuarios.localtest.me:8080/db_usuarios/1
  servicio-pedidos  : http://pedidos.localtest.me:8080/pedidos

  Estado            : bash k3d/scripts/status.sh
  Destruir cluster  : bash k3d/scripts/down.sh

  (*.localtest.me resuelve a 127.0.0.1, no hay que tocar /etc/hosts)
EOF
