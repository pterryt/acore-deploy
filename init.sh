#!/usr/bin/env bash
set -euo pipefail
: "${SERVICE_NAME:?Missing environment variables. Run via Make. Use 'make help' for options.}"

PROJECT_DIR="$(pwd)"

# init expected directories
DIRECTORIES=(
    data/dev
    data/live

    logs/auth
    logs/dev
    logs/live

    src/dev
    src/live
)

for dir in "${DIRECTORIES[@]}"; do
    mkdir -p "$PROJECT_DIR/$dir"
done


HOME_DIR="/home/${SERVICE_USER}"
LOGIN_SHELL="/usr/sbin/nologin"

# Where the project ends up inside the new home dir.
PROJECT_DEST="${HOME_DIR}/$(basename "${PROJECT_DIR}")"

if id "${SERVICE_USER}" &>/dev/null; then
    echo "Error: User '${SERVICE_USER}' already exists."
    echo
    echo "Choose another service name or remove the existing user."
    exit 1
fi

echo "Creating service account '${SERVICE_USER}'..."
useradd \
    --create-home \
    --home-dir "${HOME_DIR}" \
    --shell "${LOGIN_SHELL}" \
    --user-group \
    --comment "Rootless Podman Service Account" \
    "${SERVICE_USER}"

# Prevent password logins.
passwd -l "${SERVICE_USER}" >/dev/null

echo "Creating directory structure..."
install -d -o "${SERVICE_USER}" -g "${SERVICE_USER}" -m 700 \
    "${HOME_DIR}/.config" \
    "${HOME_DIR}/.config/containers" \
    "${HOME_DIR}/.config/containers/systemd" \
    "${HOME_DIR}/.config/containers/env" \
    "${HOME_DIR}/.local" \
    "${HOME_DIR}/.local/share" \
    "${HOME_DIR}/.local/state" \
    "${HOME_DIR}/containers" \
    "${HOME_DIR}/containers/config" \
    "${HOME_DIR}/containers/data" \
    "${HOME_DIR}/containers/logs"

echo "Enabling systemd lingering..."
loginctl enable-linger "${SERVICE_USER}"


echo
echo "Successfully created service account."
echo
echo "  Service : ${SERVICE_NAME}"
echo "  User    : ${SERVICE_USER}"
echo "  Home    : ${HOME_DIR}"

## CLONE SOURCE

clone_or_update() {
    local repo="$1"
    local branch="$2"
    local dir="$3"
    if [[ -d "$dir/.git" ]]; then
        echo "Updating $dir"
        git -C "$dir" fetch
        git -C "$dir" checkout "$branch"
        git -C "$dir" pull
    else
        echo "Cloning $repo"
        git clone --branch "$branch" "$repo" "$dir"
    fi
}
deploy_env() {
    local branch="$1"
    local install_dir="$2"
    clone_or_update \
        "$ACORE_REPO" \
        "$branch" \
        "$install_dir"
    clone_or_update \
        "$MODULE_IPP" \
        "$branch" \
        "$install_dir/modules/mod-individual-progression"
}
# -----------------------------
# Deploy
# -----------------------------

deploy_env "development" "src/test"
deploy_env "stable" "src/stable"

# Move project to service user home

echo "Moving project directory '${PROJECT_DIR}' -> '${PROJECT_DEST}'..."
if [[ -e "${PROJECT_DEST}" ]]; then
    echo "Error: '${PROJECT_DEST}' already exists. Refusing to overwrite."
    exit 1
fi
mv -- "${PROJECT_DIR}" "${PROJECT_DEST}"

echo "Setting ownership of '${PROJECT_DEST}' to ${SERVICE_USER}:${SERVICE_USER}..."
chown -R "${SERVICE_USER}:${SERVICE_USER}" "${PROJECT_DEST}"

# Start a shell as the user
echo "Switching to ${SERVICE_USER} shell."
sudo machinectl shell podmanuser@ /bin/bash
