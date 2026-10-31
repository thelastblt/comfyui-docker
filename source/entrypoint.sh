#!/bin/bash
set -euo pipefail

# Restore the standard model folder skeleton into the (possibly empty) mounted
# volume. The skeleton is the repo's own models/ tree, captured at build time,
# so new model types ship automatically on rebuild — no list to keep in sync.
# -a = preserve attributes, -R = recursive, --update=none = never overwrite existing files
echo "Checking model directories..."
mkdir -p /opt/comfyui/models
cp -aR --update=none /opt/comfyui-models-template/. /opt/comfyui/models/

# Custom node requirements: install once per node (marker file), so restarts
# are fast. Set SKIP_CUSTOM_NODE_REQUIREMENTS=1 to disable entirely.
if [ "${SKIP_CUSTOM_NODE_REQUIREMENTS:-0}" != "1" ]; then
    echo "Checking custom node requirements..."
    for node in /opt/comfyui/custom_nodes/*/; do
        [ -f "$node/requirements.txt" ] && [ ! -f "$node/.requirements-installed" ] || continue
        name=$(basename "$node")
        echo "Installing requirements for $name..."
        if /opt/venv/bin/pip install --no-cache-dir --requirement "$node/requirements.txt"; then
            touch "$node/.requirements-installed"
        fi
    done
fi

# Shared flags; any extra user args (e.g. --enable-cors-header) are appended
ARGS=( --enable-manager --port 8188 --listen 0.0.0.0 --disable-auto-launch )

if [ -z "${USER_ID:-}" ] || [ -z "${GROUP_ID:-}" ]; then
    echo "Running ComfyUI as root..."
    exec /opt/venv/bin/python main.py "${ARGS[@]}" "$@"
fi

echo "Preparing user ${USER_ID}:${GROUP_ID}..."
getent group "$GROUP_ID" >/dev/null || groupadd --gid "$GROUP_ID" comfyui
id -u "$USER_ID" >/dev/null || useradd --uid "$USER_ID" --gid "$GROUP_ID" --create-home comfyui

# Recursive chown only when ownership actually differs — avoids re-walking a
# large mounted volume on every start
if [ "$(stat -c '%u:%g' /opt/comfyui)" != "${USER_ID}:${GROUP_ID}" ]; then
    chown -R "${USER_ID}:${GROUP_ID}" /opt/comfyui /opt/venv
fi

if command -v gosu >/dev/null 2>&1; then
    exec gosu "${USER_ID}:${GROUP_ID}" /opt/venv/bin/python main.py "${ARGS[@]}" "$@"
else
    exec setpriv --reuid="$USER_ID" --regid="$GROUP_ID" --init-groups \
        /opt/venv/bin/python main.py "${ARGS[@]}" "$@"
fi
