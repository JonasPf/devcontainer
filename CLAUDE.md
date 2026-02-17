# Dev Container

## Project overview

This project defines a Docker/Podman-based development container built on Ubuntu 24.04. It provides a consistent, reproducible development environment with common tools pre-installed.

## Architecture

### Dockerfile

Builds the `devcontainer` image. Installs system packages as root, then creates a non-root `dev` user. All user-level tooling (Claude Code, fish config, vimrc) is set up under `/home/dev`. Before switching back to the `dev` user, the entire home directory is copied to `/etc/skel-dev/` so the entrypoint can seed it into an empty mounted home.

### entrypoint.sh

Container entrypoint. Checks if `~/.vimrc` exists — if not, copies the full skeleton from `/etc/skel-dev/` into `$HOME`. This handles the case where `.devhome` is mounted over `/home/dev` for the first time. Passes through to the CMD (`fish`).

### startdev.sh

Host-side launcher script. Run from a project directory to start the container. Manages:
- `.devhome/` creation (mounted as `/home/dev` for persistence)
- `.gitignore` management (adds `.devhome` entry)
- Port forwarding config (interactive prompt, saved to `.devhome/containerconfig.json`)
- Container invocation via `podman run`

### vimrc

Vim configuration copied into the image. Requires `~/.vim/{backup,swp,undo}` directories (created by the Dockerfile and entrypoint).

## Container runtime

- Image name: `devcontainer`
- Container runtime: `podman`
- User inside container: `dev` (non-root, passwordless sudo)
- Default shell: fish (with vim keybindings)
- Home directory: `/home/dev` (optionally mounted from `.devhome/`)
- Project mount: `/work`

## Installed tools

Go, Node.js + npm, Make, Vim, bat (aliased from `batcat`), Fish shell, Claude Code, git, curl, wget, jq, sudo.
