#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")/.."

source "$SCRIPT_DIR/import_env.sh"

environment="$1"

if [ -z "$environment" ]; then
  echo "Usage: ./stand_up.sh [local|prod]"
  exit 1
fi

AIRFLOW_NAMESPACE="${AIRFLOW_NAMESPACE:-airflow}"
AIRFLOW_RELEASE="${AIRFLOW_RELEASE:-airflow}"


VALUES_COMMON_FILE="$PROJECT_ROOT/deploy/airflow/values.common.yaml"
VALUES_ENV_FILE="$PROJECT_ROOT/deploy/airflow/values.${environment}.yaml"

if [ ! -f "$VALUES_COMMON_FILE" ]; then
  echo "ERROR: Missing $VALUES_COMMON_FILE"
  exit 1
fi

if [ ! -f "$VALUES_ENV_FILE" ]; then
  echo "ERROR: Missing $VALUES_ENV_FILE"
  exit 1
fi

echo "Ensuring namespace '$AIRFLOW_NAMESPACE' exists..."
kubectl get namespace "$AIRFLOW_NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$AIRFLOW_NAMESPACE"

echo "Adding/updating apache-airflow helm repo..."
helm repo add apache-airflow https://airflow.apache.org >/dev/null 2>&1 || true
helm repo update >/dev/null 2>&1 || true

AIRFLOW_ADMIN_USER="${AIRFLOW_ADMIN_USER:-admin}"
AIRFLOW_ADMIN_PASSWORD="${AIRFLOW_ADMIN_PASSWORD:-admin}"
AIRFLOW_ADMIN_EMAIL="${AIRFLOW_ADMIN_EMAIL:-admin@example.com}"
AIRFLOW_ADMIN_FIRSTNAME="${AIRFLOW_ADMIN_FIRSTNAME:-Admin}"
AIRFLOW_ADMIN_LASTNAME="${AIRFLOW_ADMIN_LASTNAME:-User}"

AIRFLOW_POSTGRES_USERNAME="${AIRFLOW_POSTGRES_USERNAME:-airflow}"
AIRFLOW_POSTGRES_PASSWORD="${AIRFLOW_POSTGRES_PASSWORD:-airflow}"
AIRFLOW_POSTGRES_DATABASE="${AIRFLOW_POSTGRES_DATABASE:-airflow}"
AIRFLOW_POSTGRES_POSTGRES_PASSWORD="${AIRFLOW_POSTGRES_POSTGRES_PASSWORD:-$AIRFLOW_POSTGRES_PASSWORD}"
AIRFLOW_POSTGRES_IMAGE_REPOSITORY="${AIRFLOW_POSTGRES_IMAGE_REPOSITORY:-bitnami/postgresql}"
AIRFLOW_POSTGRES_IMAGE_TAG="${AIRFLOW_POSTGRES_IMAGE_TAG:-latest}"

echo "Installing/upgrading Airflow into namespace '$AIRFLOW_NAMESPACE' (executor=LocalExecutor, bundled Postgres)..."
helm upgrade --install "$AIRFLOW_RELEASE" apache-airflow/airflow \
  --namespace "$AIRFLOW_NAMESPACE" \
  --create-namespace \
  --wait \
  --timeout "${HELM_TIMEOUT:-20m}" \
  -f "$VALUES_COMMON_FILE" \
  -f "$VALUES_ENV_FILE" \
  --set "data.metadataConnection.protocol=postgresql" \
  --set "data.metadataConnection.host=${AIRFLOW_RELEASE}-postgresql" \
  --set "data.metadataConnection.port=5432" \
  --set "data.metadataConnection.user=$AIRFLOW_POSTGRES_USERNAME" \
  --set "data.metadataConnection.pass=$AIRFLOW_POSTGRES_PASSWORD" \
  --set "data.metadataConnection.db=$AIRFLOW_POSTGRES_DATABASE" \
  --set "postgresql.image.repository=$AIRFLOW_POSTGRES_IMAGE_REPOSITORY" \
  --set "postgresql.image.tag=$AIRFLOW_POSTGRES_IMAGE_TAG" \
  --set "postgresql.auth.username=$AIRFLOW_POSTGRES_USERNAME" \
  --set "postgresql.auth.password=$AIRFLOW_POSTGRES_PASSWORD" \
  --set "postgresql.auth.database=$AIRFLOW_POSTGRES_DATABASE" \
  --set "postgresql.auth.postgresPassword=$AIRFLOW_POSTGRES_POSTGRES_PASSWORD" \
  --set "webserver.defaultUser.username=$AIRFLOW_ADMIN_USER" \
  --set "webserver.defaultUser.password=$AIRFLOW_ADMIN_PASSWORD" \
  --set "webserver.defaultUser.email=$AIRFLOW_ADMIN_EMAIL" \
  --set "webserver.defaultUser.firstName=$AIRFLOW_ADMIN_FIRSTNAME" \
  --set "webserver.defaultUser.lastName=$AIRFLOW_ADMIN_LASTNAME"

echo "Airflow install/upgrade complete"