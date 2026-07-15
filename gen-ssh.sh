#!/usr/bin/env bash
# generate ssh key to be manually passed to remote provider for access to
# private repositories
set -euo pipefail
: "${SERVICE_NAME:?Missing environment variables. Run via Make. Use 'make help' for options.}"

if [[ "$(whoami)" == "$SERVICE_USER" ]]; then
    echo "Error: Do not run this script as $SERVICE_USER. Underprivileged service \
    user should not have remote access."
    exit 1
fi

key_dir="$HOME/.ssh"
key_path="$key_dir/$REMOTE_IDENTITY"

mkdir -p "$key_dir"

if [ -e "$key_path" ]; then
    echo "Key already exists: $key_path"
    exit 1
fi

ssh-keygen \
    -t ed25519 \
    -C "$REMOTE_IDENTITY" \
    -f "$key_path" \
    -N ""

echo
echo "Public key to add to remote provider:"
echo "----------------------------------------"
cat "$key_path.pub"
echo "----------------------------------------"
echo
echo "Private key: $key_path"
echo "Public key : $key_path.pub"