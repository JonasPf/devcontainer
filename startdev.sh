#!/bin/bash
set -e

IMAGE="devcontainer"
DIRNAME="$(basename "$(pwd)" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9._-]/-/g')"
SUFFIX="$(head -c4 /dev/urandom | xxd -p)"
CONTAINER_NAME="dev-${DIRNAME}-${SUFFIX}"
DEVHOME=".devhome"
CONFIG="$DEVHOME/containerconfig.json"
SKIP_PORTS=false

# Create .devhome if it doesn't exist
mkdir -p "$DEVHOME"

# Add .devhome to .gitignore if the file exists and the entry is missing
if [ -f .gitignore ]; then
    if ! grep -qx "$DEVHOME" .gitignore; then
        echo "$DEVHOME" >> .gitignore
    fi
fi

# Load or ask for port config
if [ -f "$CONFIG" ]; then
    PORTS=$(jq -r '.ports // [] | .[]' "$CONFIG")
    if [ -n "$PORTS" ]; then
        echo "Using saved ports: $(echo "$PORTS" | tr '\n' ' ')"
    else
        echo "No ports configured."
    fi
    echo -n "Keep this config? [Y/n/skip] "
    read -r answer
    if [[ "$answer" =~ ^[Ss] ]]; then
        SKIP_PORTS=true
    elif [[ "$answer" =~ ^[Nn] ]]; then
        PORTS=""
        rm "$CONFIG"
    fi
fi

if [ ! -f "$CONFIG" ]; then
    echo "Enter ports to forward (comma-separated, e.g. 8080,9090), or leave empty for none:"
    read -r port_input
    # Parse comma/space separated ports into an array
    IFS=', ' read -ra PORT_ARRAY <<< "$port_input"
    # Write config
    jq -n --argjson ports "$(printf '%s\n' "${PORT_ARRAY[@]}" | jq -R 'select(length > 0) | tonumber' | jq -s '.')" \
        '{ports: $ports}' > "$CONFIG"
    PORTS=$(jq -r '.ports // [] | .[]' "$CONFIG")
fi

# Build port flags
PORT_FLAGS=""
if [ "$SKIP_PORTS" = false ]; then
    while IFS= read -r port; do
        [ -n "$port" ] && PORT_FLAGS="$PORT_FLAGS -p $port:$port"
    done <<< "$PORTS"
else
    echo "Skipping port forwarding."
fi

# Run the container
exec podman run -it --rm \
    --name "$CONTAINER_NAME" \
    $PORT_FLAGS \
    -e HOST_UID="$(id -u)" \
    -e HOST_GID="$(id -g)" \
    -v "$(pwd):/work" \
    -v "$(pwd)/$DEVHOME:/home/dev" \
    -w /work \
    "$IMAGE"
