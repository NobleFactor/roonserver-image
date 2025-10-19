# Roon Server Docker Image

A minimal, container-friendly way to run Roon Server with sane defaults and an idempotent first-run installer.

This image is intended for local use and was developed and tested primarily on macOS using OrbStack as a drop-in replacement for Docker Desktop. It also runs on Linux hosts.

## Features

- Automatic first-run installation using `assets/install-roonserver`
- Clean separation of app and data locations
- Docker Compose and Makefile workflows
- macOS-friendly defaults and guidance
- Ubuntu base with required dependencies preinstalled

## Quick Start

Pick one path to get running quickly.

### Using Make (recommended)

```bash
# Show available targets
make help

# Build the image and create the container (no start)
make New-RoonServer

# Start the container (creates ~/Documents/Roon/{Backup,Data,Music} if missing)
make Start-RoonServer
```

### Using Docker Compose

```bash
# Start in the background
docker compose up -d

# Follow logs
docker compose logs -f
```

### Using Docker CLI

```bash
docker run -d \
  --name roonserver \
  --net=host \
  -v ~/Documents/Roon/Backup:/opt/local/var/roon/backup \
  -v ~/Documents/Roon/Data:/opt/local/var/roon/data \
  -v ~/Documents/Roon/Music:/opt/local/var/roon/music \
  noblefactor/roonserver:latest
```

## macOS Notes

- Built and tested on macOS with [OrbStack](https://orbstack.dev/) (works as a drop-in for Docker Desktop).
- For testing, use the [Roon Remote app](https://apps.apple.com/us/app/roon-remote/id1014764083) on a separate device (e.g., iPad) to avoid conflicts with Roon for Mac on the same machine.
- On first run, macOS will prompt you to allow file access to the Backup, Data, and Music folders. The defaults map to:
  - `~/Documents/Roon/Backup`
  - `~/Documents/Roon/Data`
  - `~/Documents/Roon/Music`

  See `docker-compose.yml` to change these.

## Configuration

Environment variables used by the installer and service:

- `ROON_SERVERROOT` (default: `/opt/local/share/roon/roonserver`) — app install location
- `ROON_DATAROOT` (default: `/opt/local/var/roon`) — data root, containing:
  - `data` (database/config)
  - `music` (library root)
  - `backup` (backup target)

Installer options (passed to the container entrypoint):

- `--package <address>` — URL for the Roon Server Linux x64 tarball (defaults to official URL)
- `--timezone <tz>` — Container timezone (default `Etc/UTC`)
- `--help` — Usage

## Volumes

By default, the Compose file binds the following host paths:

- `~/Documents/Roon/Backup` → `/opt/local/var/roon/backup`
- `~/Documents/Roon/Data` → `/opt/local/var/roon/data`
- `~/Documents/Roon/Music` → `/opt/local/var/roon/music`

Important: App and data locations must be different to ensure smooth upgrades. The installer checks and will refuse a bad setup.

## Networking

- The container uses `network_mode: host` to allow Roon discovery and audio endpoints.

- These incoming ports must be open to network traffic:
    * TCP: 9100-9200
    * UDP: 9003
Reference: https://portforward.com/roon/.

- If you are on Linux and your host has multiple networks, endpoints may not be discovered. In this case, consider using a macvlan network and attach the container to the LAN where endpoints live.

- Macvlan networks are only supported on Linux so the macvlan option is unavailable on macOS and Windows.

## Make Targets

- `help` — Show this help text
- `New-RoonServer` — Build the image and create the container (no start)
- `Start-RoonServer` — Start the container; ensures host directories exist
- `Restart-RoonServer` — Restart the running container
- `Stop-RoonServer` — Stop the container
- `Start-RoonServerShell` — Open an interactive shell inside the container

## How It Works

On first start, the entrypoint runs `assets/install-roonserver` which:

1. Verifies prerequisites and sets timezone
2. Downloads and unpacks Roon Server into `ROON_SERVERROOT`
3. Ensures `ROON_DATAROOT` structure exists (`data`, `music`, `backup`)
4. Writes a systemd unit (bare metal) or runs directly (in container)
5. Starts Roon Server

Subsequent starts skip installation and start Roon Server immediately.

## Development

- Build the image: `make New-RoonServer`
- Open a shell: `make Start-RoonServerShell`
- Manual build: `docker buildx build --platform linux/amd64 --tag noblefactor/roonserver:1.0.0-preview.2 . --progress=plain`

## License

This repository’s code is licensed under MIT. See `LICENSE.md`.
Roon Server software is governed by the [Roon Labs Terms and Conditions](https://roon.app/en/termsandconditions).

## Support

- Issues with this Docker image: open an issue in this repository
- Roon Server product support: visit [Roon Labs Support](https://roon.app/support)
