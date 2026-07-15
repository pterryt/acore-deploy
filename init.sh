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


## CREATE SERVICE USER

USER_NAME="${SERVICE_NAME}-user"
HOME_DIR="/home/${USER_NAME}"
LOGIN_SHELL="/usr/sbin/nologin"

# Where the project ends up inside the new home dir.
PROJECT_DEST="${HOME_DIR}/$(basename "${PROJECT_DIR}")"

if id "${USER_NAME}" &>/dev/null; then
    echo "Error: User '${USER_NAME}' already exists."
    echo
    echo "Choose another service name or remove the existing user."
    exit 1
fi

echo "Creating service account '${USER_NAME}'..."
useradd \
    --create-home \
    --home-dir "${HOME_DIR}" \
    --shell "${LOGIN_SHELL}" \
    --user-group \
    --comment "Rootless Podman Service Account" \
    "${USER_NAME}"

# Prevent password logins.
passwd -l "${USER_NAME}" >/dev/null

echo "Creating directory structure..."
install -d -o "${USER_NAME}" -g "${USER_NAME}" -m 700 \
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
loginctl enable-linger "${USER_NAME}"

echo "Moving project directory '${PROJECT_DIR}' -> '${PROJECT_DEST}'..."
if [[ -e "${PROJECT_DEST}" ]]; then
    echo "Error: '${PROJECT_DEST}' already exists. Refusing to overwrite."
    exit 1
fi
mv -- "${PROJECT_DIR}" "${PROJECT_DEST}"

echo "Setting ownership of '${PROJECT_DEST}' to ${USER_NAME}:${USER_NAME}..."
chown -R "${USER_NAME}:${USER_NAME}" "${PROJECT_DEST}"

echo
echo "Successfully created service account."
echo
echo "  Service : ${SERVICE_NAME}"
echo "  User    : ${USER_NAME}"
echo "  Home    : ${HOME_DIR}"
echo "  Shell   : ${LOGIN_SHELL}"
echo "  Project : ${PROJECT_DEST}"

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


