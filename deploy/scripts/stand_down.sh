#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/import_env.sh"

AIRFLOW_NAMESPACE="${AIRFLOW_NAMESPACE:-airflow}"
AIRFLOW_RELEASE="${AIRFLOW_RELEASE:-airflow}"

echo "Uninstalling Airflow Helm release '$AIRFLOW_RELEASE' (if exists)..."
helm uninstall "$AIRFLOW_RELEASE" --namespace "$AIRFLOW_NAMESPACE" >/dev/null 2>&1 || true

if [ "${AIRFLOW_DELETE_NAMESPACE:-false}" = "true" ]; then
  echo "Deleting namespace $AIRFLOW_NAMESPACE..."
  kubectl delete namespace "$AIRFLOW_NAMESPACE" --ignore-not-found
fi