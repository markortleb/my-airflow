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

AIRFLOW_DB_HOST="${PGHOST:-}"
AIRFLOW_DB_PORT="${PGPORT:-}"
AIRFLOW_DB_NAME="${PGDATABASE:-}"
AIRFLOW_DB_USER="${PGUSER:-}"
AIRFLOW_DB_PASS="${PGPASSWORD:-}"
AIRFLOW_DB_SSLMODE="${PGSSLMODE:-disable}"

CERT_MANAGER_NAMESPACE="${CERT_MANAGER_NAMESPACE:-cert-manager}"
CERT_MANAGER_RELEASE="${CERT_MANAGER_RELEASE:-cert-manager}"
CERT_MANAGER_VERSION="${CERT_MANAGER_VERSION:-v1.14.5}"

CERT_MANAGER_EMAIL="${CERT_MANAGER_EMAIL:-}"
CERT_MANAGER_ACME_SERVER="${CERT_MANAGER_ACME_SERVER:-https://acme-v02.api.letsencrypt.org/directory}"
CERT_MANAGER_INGRESS_CLASS="${CERT_MANAGER_INGRESS_CLASS:-traefik}"

if [ "$environment" = "prod" ]; then
  if [ -z "$CERT_MANAGER_EMAIL" ]; then
    echo "ERROR: CERT_MANAGER_EMAIL is required for prod (set it in .env.prod or .env)"
    exit 1
  fi

  echo "Ensuring namespace '$CERT_MANAGER_NAMESPACE' exists..."
  kubectl get namespace "$CERT_MANAGER_NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$CERT_MANAGER_NAMESPACE"

  echo "Adding/updating jetstack helm repo..."
  helm repo add jetstack https://charts.jetstack.io >/dev/null 2>&1 || true
  helm repo update >/dev/null 2>&1 || true

  echo "Installing/upgrading cert-manager ($CERT_MANAGER_VERSION) into namespace '$CERT_MANAGER_NAMESPACE'..."
  helm upgrade --install "$CERT_MANAGER_RELEASE" jetstack/cert-manager \
    --namespace "$CERT_MANAGER_NAMESPACE" \
    --create-namespace \
    --set installCRDs=true \
    --version "$CERT_MANAGER_VERSION"

  echo "Applying ClusterIssuer letsencrypt-prod (HTTP-01, ingressClass=$CERT_MANAGER_INGRESS_CLASS)..."
  cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    email: ${CERT_MANAGER_EMAIL}
    server: ${CERT_MANAGER_ACME_SERVER}
    privateKeySecretRef:
      name: letsencrypt-prod-account-key
    solvers:
      - http01:
          ingress:
            class: ${CERT_MANAGER_INGRESS_CLASS}
EOF

  echo "cert-manager + ClusterIssuer ready (check: kubectl describe clusterissuer letsencrypt-prod)"
fi

if [ -z "$AIRFLOW_DB_HOST" ] || [ -z "$AIRFLOW_DB_PORT" ] || [ -z "$AIRFLOW_DB_NAME" ] || [ -z "$AIRFLOW_DB_USER" ] || [ -z "$AIRFLOW_DB_PASS" ]; then
  echo "ERROR: PGHOST, PGPORT, PGDATABASE, PGUSER, and PGPASSWORD are required (set them in your env file)"
  exit 1
fi

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

echo "Installing/upgrading Airflow into namespace '$AIRFLOW_NAMESPACE' (executor=LocalExecutor, external Postgres)..."
helm upgrade --install "$AIRFLOW_RELEASE" apache-airflow/airflow \
  --namespace "$AIRFLOW_NAMESPACE" \
  --create-namespace \
  -f "$VALUES_COMMON_FILE" \
  -f "$VALUES_ENV_FILE" \
  --set "data.metadataConnection.host=$AIRFLOW_DB_HOST" \
  --set "data.metadataConnection.port=$AIRFLOW_DB_PORT" \
  --set "data.metadataConnection.db=$AIRFLOW_DB_NAME" \
  --set "data.metadataConnection.user=$AIRFLOW_DB_USER" \
  --set "data.metadataConnection.pass=$AIRFLOW_DB_PASS" \
  --set "data.metadataConnection.sslmode=$AIRFLOW_DB_SSLMODE" \
  --set "webserver.defaultUser.username=$AIRFLOW_ADMIN_USER" \
  --set "webserver.defaultUser.password=$AIRFLOW_ADMIN_PASSWORD" \
  --set "webserver.defaultUser.email=$AIRFLOW_ADMIN_EMAIL" \
  --set "webserver.defaultUser.firstName=$AIRFLOW_ADMIN_FIRSTNAME" \
  --set "webserver.defaultUser.lastName=$AIRFLOW_ADMIN_LASTNAME"

echo "Airflow install/upgrade complete"