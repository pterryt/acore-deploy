#!/usr/bin/env bash
set -euo pipefail
: "${SERVICE_NAME:?Missing environment variables. Run via Make. Use 'make help' for options.}"

if [[ "$(whoami)" != "$SERVICE_USER" ]]; then
    echo "Error: This script must be run as $SERVICE_USER. Services should be owned by service user."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SYSTEMD_DIR="$HOME/.config/containers/systemd"
mkdir -p "$SYSTEMD_DIR"

# remove old acore files
find "$SYSTEMD_DIR" -maxdepth 1 -type f -name "${SERVICE_NAME}*" -delete
# install quadlets ignoring dist files
for file in "$SCRIPT_DIR"/systemd/*; do
    [[ "$file" == *.dist ]] && continue
    cp -f "$file" "$SYSTEMD_DIR/$(basename "$file")"
done
systemctl --user daemon-reload
