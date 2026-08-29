#!/usr/bin/env bash
set -euo pipefail

# Resumen rapido del estado del entorno local.

ARGOCD_NS="argocd"
APPS_NS="microservicios"

echo "===== Clusters k3d ====="
k3d cluster list
echo
echo "===== Nodos ====="
kubectl get nodes -o wide
echo
echo "===== Pods Argo CD ====="
kubectl -n "${ARGOCD_NS}" get pods
echo
echo "===== Applications ====="
kubectl -n "${ARGOCD_NS}" get applications
echo
echo "===== Recursos en '${APPS_NS}' ====="
kubectl -n "${APPS_NS}" get all
echo
echo "===== Ingress ====="
kubectl get ingress -A
