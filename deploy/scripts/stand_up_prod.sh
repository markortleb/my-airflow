#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/k3s-vps.yaml}"
export ENV_FILE="${ENV_FILE:-$SCRIPT_DIR/../../.env.prod}"
export CERT_MANAGER_MANAGED="${CERT_MANAGER_MANAGED:-true}"

"$SCRIPT_DIR/stand_up.sh" prod
