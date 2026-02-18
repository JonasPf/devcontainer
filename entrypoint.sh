#!/bin/bash
# Runs as root. Adjusts the dev user's UID/GID to match the host,
# seeds default dotfiles, then drops to the dev user.

USERNAME="dev"
TARGET_UID="${HOST_UID:-1000}"
TARGET_GID="${HOST_GID:-1000}"
CURRENT_UID=$(id -u "$USERNAME")
CURRENT_GID=$(id -g "$USERNAME")

if [ "$TARGET_GID" != "$CURRENT_GID" ]; then
    groupmod -g "$TARGET_GID" "$USERNAME"
fi

if [ "$TARGET_UID" != "$CURRENT_UID" ]; then
    usermod -u "$TARGET_UID" "$USERNAME"
fi

export HOME="/home/$USERNAME"
chown -R "$TARGET_UID:$TARGET_GID" "$HOME"

# Seed default config files if this is the first run with a mounted home
if [ ! -f "$HOME/.vimrc" ]; then
    cp -a /etc/skel-dev/. "$HOME"/
    chown -R "$TARGET_UID:$TARGET_GID" "$HOME"
fi

exec setpriv --reuid="$TARGET_UID" --regid="$TARGET_GID" --init-groups "$@"
