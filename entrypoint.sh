#!/bin/bash
# Seed default config files into the home directory if they don't exist yet.
# This handles the case where an empty .devhome is mounted over /home/dev.

# Fix ownership of the mounted home directory
sudo chown -R "$(id -u):$(id -g)" "$HOME"

if [ ! -f "$HOME/.vimrc" ]; then
    cp -a /etc/skel-dev/. "$HOME"/
fi

exec "$@"
