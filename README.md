# Dev Container

Ubuntu-based development container with the following tools pre-installed:

- Go 1.23.6
- Node.js 22 LTS + npm
- Make
- Vim (with custom vimrc)
- bat (aliased from `batcat`)
- Fish shell (default, with vim mode)
- Claude Code (native installer)
- git, curl, wget, jq

Runs as a non-root user (`dev`) with passwordless sudo.

## Files

| File | Purpose |
|------|---------|
| `Dockerfile` | Container image definition |
| `vimrc` | Vim configuration, copied into the image |
| `entrypoint.sh` | Seeds default dotfiles into a mounted home directory on first run |
| `startdev.sh` | Interactive launcher script for starting the container |

## Build

```bash
podman build -t devcontainer .
```

## Run

From your project directory, run the start script:

```bash
/path/to/startdev.sh
```

### First run

1. Creates a `.devhome` directory in your project — this is mounted as the container's home directory (`/home/dev`), so shell history, vim undo, config changes, etc. persist across restarts.
2. Adds `.devhome` to your `.gitignore` if one exists.
3. Asks which ports to forward (comma-separated, e.g. `8080,9090`). The selection is saved to `.devhome/containerconfig.json`.
4. Starts the container.

### Subsequent runs

The saved port config is loaded from `.devhome/containerconfig.json`. You'll be prompted to confirm or reconfigure.

### Skip port forwarding

When prompted with `Keep this config? [Y/n/skip]`, type `s` or `skip` to start the container without forwarding any ports. The saved config is not changed. This is useful when another container is already using the configured ports and you need a second instance for non-server work.

### What `startdev.sh` does

- Creates `.devhome/` if missing
- Appends `.devhome` to `.gitignore` if the file exists and the entry is missing
- Reads or prompts for port forwarding config
- Saves port config to `.devhome/containerconfig.json`
- Runs the container with:
  - Current directory mounted at `/work`
  - `.devhome/` mounted at `/home/dev`
  - Requested ports forwarded

## Home directory persistence

When `.devhome` is mounted as `/home/dev`, it starts empty. The container's entrypoint (`entrypoint.sh`) detects this and copies default dotfiles (vimrc, fish config, Claude Code installation) from `/etc/skel-dev/` into the home directory. On subsequent runs the existing files in `.devhome` are preserved.

## Port config format

`.devhome/containerconfig.json`:

```json
{
  "ports": [8080, 9090]
}
```
