#!/usr/bin/env bash
set -euo pipefail

# Elimina por completo el cluster local (incluye Argo CD y los microservicios).

CLUSTER="microservicios-devops"

k3d cluster delete "${CLUSTER}"
echo "Cluster '${CLUSTER}' eliminado."
