#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"

"$SCRIPT_DIR/stand_up.sh" local
