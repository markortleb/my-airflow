#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/k3s-vps.yaml}"

"$SCRIPT_DIR/stand_up.sh" prod
