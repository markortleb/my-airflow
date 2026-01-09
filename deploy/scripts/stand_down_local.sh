#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"
export ENV_FILE="${ENV_FILE:-$SCRIPT_DIR/../../.env.local}"

"$SCRIPT_DIR/stand_down.sh"
