#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/import_env.sh"

AIRFLOW_NAMESPACE="${AIRFLOW_NAMESPACE:-airflow}"
AIRFLOW_RELEASE="${AIRFLOW_RELEASE:-airflow}"

CERT_MANAGER_MANAGED="${CERT_MANAGER_MANAGED:-false}"

CERT_MANAGER_NAMESPACE="${CERT_MANAGER_NAMESPACE:-cert-manager}"
CERT_MANAGER_RELEASE="${CERT_MANAGER_RELEASE:-cert-manager}"

echo "Uninstalling Airflow Helm release '$AIRFLOW_RELEASE' (if exists)..."
helm uninstall "$AIRFLOW_RELEASE" --namespace "$AIRFLOW_NAMESPACE" >/dev/null 2>&1 || true

if [ "${AIRFLOW_DELETE_NAMESPACE:-false}" = "true" ]; then
  echo "Deleting namespace $AIRFLOW_NAMESPACE..."
  kubectl delete namespace "$AIRFLOW_NAMESPACE" --ignore-not-found
fi

if [ "$CERT_MANAGER_MANAGED" = "true" ]; then
  echo "Deleting ClusterIssuer letsencrypt-prod (if exists)..."
  kubectl delete clusterissuer letsencrypt-prod --ignore-not-found

  echo "Uninstalling cert-manager Helm release '$CERT_MANAGER_RELEASE' (if exists)..."
  helm uninstall "$CERT_MANAGER_RELEASE" --namespace "$CERT_MANAGER_NAMESPACE" >/dev/null 2>&1 || true
fi

if [ "${CERT_MANAGER_DELETE_NAMESPACE:-false}" = "true" ]; then
  echo "Deleting namespace $CERT_MANAGER_NAMESPACE..."
  kubectl delete namespace "$CERT_MANAGER_NAMESPACE" --ignore-not-found
fi