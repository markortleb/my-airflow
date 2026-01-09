#!/bin/bash

# Resolve the project root based on this script's location, not the current working directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
ENV_FILE="${ENV_FILE:-${PROJECT_ROOT}/.env}"

# Load the top-level .env file
if [ -f "${ENV_FILE}" ]; then
  set -o allexport
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
  set +o allexport
else
  echo "WARNING: ${ENV_FILE} not found!"
fi