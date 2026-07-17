#!/usr/bin/env bash
set -euo pipefail

: "${SERVICE_NAME:?Missing environment variables}"
: "${SERVICE_USER:?Missing environment variables}"

# Nothing to clean up if the user doesn't exist.
if ! id "${SERVICE_USER}" >/dev/null 2>&1; then
    echo "Service user '${SERVICE_USER}' does not exist. Nothing to clean up."
    exit 0
fi

HOME_DIR="/home/${SERVICE_USER}"
PROJECT_NAME="azerothcore"
PROJECT_DEST="${HOME_DIR}/${PROJECT_NAME}"

echo "Stopping lingering..."
sudo loginctl disable-linger "${SERVICE_USER}" || true

echo "Removing project..."
if [[ -d "${PROJECT_DEST}" ]]; then
    sudo rm -rf "${PROJECT_DEST}"
fi

if loginctl list-users --no-legend | awk '{print $2}' | grep -qx "${SERVICE_USER}"; then
    echo "Stopping user processes..."
    sudo loginctl terminate-user "${SERVICE_USER}"
fi

echo "Removing service user..."
sudo userdel --remove "${SERVICE_USER}"

echo "Cleanup complete."
