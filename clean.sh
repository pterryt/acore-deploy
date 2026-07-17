#!/usr/bin/env bash
set -euo pipefail

: "${SERVICE_NAME:?Missing environment variables}"
: "${SERVICE_USER:?Missing environment variables}"

HOME_DIR="/home/${SERVICE_USER}"
PROJECT_NAME="azerothcore"
PROJECT_DEST="${HOME_DIR}/${PROJECT_NAME}"

echo "Stopping lingering..."
sudo loginctl disable-linger "${SERVICE_USER}" || true

echo "Removing project..."
if [[ -d "${PROJECT_DEST}" ]]; then
    sudo rm -rf "${PROJECT_DEST}"
fi

echo "Stopping and user processes..."
sudo loginctl terminate-user "$SERVICE_USER"

echo "Removing service user..."
if id "${SERVICE_USER}" >/dev/null 2>&1; then
    sudo userdel --remove "${SERVICE_USER}"
fi

echo "Cleanup complete."
