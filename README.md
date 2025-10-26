# Roon Server Docker Image

A minimal, container-friendly way to run Roon Server with sane defaults and an idempotent first-run installer.

This image is intended for local use and was developed and tested primarily on macOS using OrbStack as a drop-in replacement for Docker Desktop. It also runs on Linux hosts.

## Features

- Automatic first-run installation using `assets/Install-RoonServerService`
- Clean separation of app and data locations
- Docker Compose and Makefile workflows
- macOS-friendly defaults and guidance (native install via `tools/Darwin/Install-RoonServer`)
- Debian Trixie base with Avahi mDNS support preinstalled
- Linux macvlan network support for multi-network hosts

## Quick Start

Pick one path to get running quickly.

### Using Make (recommended for Linux)

The Makefile provides the most control and is designed primarily for Linux hosts with macvlan network support.

```bash
# Show available targets
make help

# Build the image
make New-RoonServer

# Create the container with macvlan networking (Linux only, requires IP_RANGE)
make New-RoonServerContainer IP_RANGE=192.168.1.8/29

# Start the container (creates ~/Documents/Roon/{Backup,Data,Music} if missing)
make Start-RoonServer
```

### Using Docker Compose (simpler for macOS/OrbStack)

```bash
# Start in the background
docker compose up -d

# Follow logs
docker compose logs -f
```

**Note:** The compose file references an external macvlan network. On macOS/OrbStack, you may need to adjust `compose.yaml` to use `network_mode: host` instead of the external network.

### Using Docker CLI

```bash
docker run -d \
  --name roonserver \
  --net=host \
  -v ~/Documents/Roon/Backup:/opt/local/var/roon/backup \
  -v ~/Documents/Roon/Data:/opt/local/var/roon/data \
  -v ~/Documents/Roon/Music:/opt/local/var/roon/music \
  noblefactor/roonserver:1.0.0-preview.2
```

### Native macOS Installation (Recommended for macOS)

For better mDNS reliability on macOS, consider installing Roon Server natively as a LaunchDaemon:

```bash
cd tools/Darwin
sudo ./Install-RoonServer --help
sudo ./Install-RoonServer
```

See `tools/Darwin/README.md` for complete documentation, including shell completions.

## macOS Notes

**⚠️ Containerized Roon Server is not supported on macOS.**

Roon requires mDNS for endpoint discovery, but mDNS traffic cannot be reliably forwarded between the physical network and Docker host or bridge networks. A macvlan network is required for proper mDNS operation, and macvlan networks are only supported on Linux. Neither Docker Desktop nor OrbStack provide a solution to this problem.

**Use the native installer instead:**

```bash
cd tools/Darwin
sudo ./Install-RoonServer --help
sudo ./Install-RoonServer
```

The native installer:

- Installs Roon Server as a system LaunchDaemon
- Provides reliable mDNS/Bonjour integration
- Includes shell completions (bash/zsh) and man page documentation
- See `tools/Darwin/README.md` for complete documentation

**For testing purposes only** (if you must use containers on macOS):

- Built and tested with [OrbStack](https://orbstack.dev/) as a Docker Desktop replacement
- Use the [Roon Remote app](https://apps.apple.com/us/app/roon-remote/id1014764083) on a separate device (e.g., iPad) to avoid conflicts with Roon for Mac
- On first run, macOS will prompt for file access to the Backup, Data, and Music folders:
  - `~/Documents/Roon/Backup`
  - `~/Documents/Roon/Data`
  - `~/Documents/Roon/Music`
- Modify `compose.yaml` to use `network_mode: host` instead of the external macvlan network

### Reference

1. [OrbStack Host Networking](https://docs.orbstack.dev/docker/host-networking)

## Configuration

Environment variables used by the installer and service:

- `ROON_SERVERROOT` (default: `/opt/local/share/roon/roonserver`) — app install location
- `ROON_DATAPREFIX` (default: `/opt/local/var/roon`) — data root, containing:
  - `data` (database/config)
  - `music` (library root)
  - `backup` (backup target)
- `ROON_USER` (default: `roon`) — system user to run the service
- `ROON_USER_UID` (optional) — User ID for the roon user (useful when mounting host directories)
- `ROON_USER_GID` (optional) — Group ID for the roon user

Installer options (passed to the container entrypoint or used with `tools/Darwin/Install-RoonServer`):

- `--roon-package <address>` — URL for the Roon Server Linux x64 tarball (defaults to official URL)
- `--roon-user <user>[:<uid>[:<gid>]]` — Specify the user (and optionally UID/GID) for the service
- `--roon-dataprefix <path>` — Override the data prefix location
- `--timezone <tz>` — Container timezone (default `Etc/UTC`)
- `--help` — Usage

## Volumes

By default, the Compose file binds the following host paths:

- `~/Documents/Roon/Backup` → `/opt/local/var/roon/backup`
- `~/Documents/Roon/Data` → `/opt/local/var/roon/data`
- `~/Documents/Roon/Music` → `/opt/local/var/roon/music`

Important: App and data locations must be different to ensure smooth upgrades. The installer checks and will refuse a bad setup.

## Networking

- By default, the container uses an external macvlan network for direct LAN connectivity (Linux only).

- For macOS/OrbStack, modify `compose.yaml` to use `network_mode: host` instead of the external network.

- These incoming ports must be open to network traffic:
  - TCP: 9100-9200
  - UDP: 9003

  Reference: [Roon port forwarding](https://portforward.com/roon/).

- **Linux with multiple networks:** Use macvlan networking to ensure endpoints on your LAN are discovered. The Makefile automates this:
  - Detects the default network interface
  - Creates a macvlan network with the specified IP range
  - Validates network configuration

- **macvlan limitations:** Only supported on Linux hosts. Not available on macOS or Windows.

### Setting up macvlan (Linux)

```bash
# The Makefile handles network creation automatically
make New-RoonServerContainer IP_RANGE=192.168.1.8/29
```

Environment variables for network configuration:

- `IP_RANGE` — Required CIDR for the macvlan network subnet (e.g., `192.168.1.0/24`)
- `MACVLAN_NETWORK_NAME` — Override the network name (default: `roonserver-<interface>`)

## Make Targets

Run `make help` for complete documentation. Key targets:

- `help` — Show detailed help text with all variables and examples
- `New-RoonServer` — Build the Docker image
- `New-RoonServerContainer` — Create the container with macvlan network (Linux only, requires `IP_RANGE`)
- `Start-RoonServer` — Start the container; ensures host directories exist
- `Restart-RoonServer` — Restart the running container
- `Stop-RoonServer` — Stop the container
- `Start-RoonServerShell` — Open an interactive shell inside the container
- `Clean-Project` — Remove container and image
- `Clean-System` — Run docker system prune after Clean-Project

## How It Works

On first start, the entrypoint (`assets/roonserver-service`) runs:

1. **Start Avahi daemon** (`assets/Start-AvahiDaemon`) — Starts D-Bus and Avahi for mDNS support
2. **Install and run Roon Server** (`assets/Install-RoonServerService`) which:
   - Verifies prerequisites and sets timezone
   - Downloads and unpacks Roon Server into `ROON_SERVERROOT`
   - Ensures `ROON_DATAPREFIX` structure exists (`data`, `music`, `backup`)
   - Creates systemd unit (bare metal) or runs directly (in container)
   - Configures the `roon` user with proper UID/GID if specified
   - Starts Roon Server

Subsequent starts detect the existing installation and start Roon Server immediately.

## Development

### Building and Testing

```bash
# Build the image
make New-RoonServer

# Create container with macvlan (Linux)
make New-RoonServerContainer IP_RANGE=192.168.1.8/29

# Start and test
make Start-RoonServer

# Open a shell for debugging
make Start-RoonServerShell
```

### Manual Docker Build

```bash
docker buildx build --platform linux/amd64 \
  --tag noblefactor/roonserver:1.0.0-preview.2 \
  --progress=plain .
```

### Native macOS Development

```bash
cd tools/Darwin

# View documentation
man ./Install-RoonServer.1

# Test installation
sudo ./Install-RoonServer --help
sudo ./Install-RoonServer

# Install shell completions (see tools/Darwin/README.md)
```

### Project Structure

```text
.
├── assets/
│   ├── Install-RoonServerService  # Main installer script
│   ├── Start-AvahiDaemon          # mDNS service starter
│   ├── Uninstall-RoonServer       # Uninstaller (for bare metal)
│   └── roonserver-service         # Container entrypoint
├── tools/
│   └── Darwin/
│       ├── Install-RoonServer     # Native macOS installer
│       ├── Install-RoonServer.1   # Man page
│       ├── Install-RoonServer.bash-completion
│       ├── _Install-RoonServer    # Zsh completion
│       └── README.md
├── compose.yaml                   # Docker Compose configuration
├── Dockerfile                     # Container image definition
└── makefile                       # Build and deployment automation
```

## License

This repository’s code is licensed under MIT. See `LICENSE.md`.
Roon Server software is governed by the [Roon Labs Terms and Conditions](https://roon.app/en/termsandconditions).

## Support

- Issues with this Docker image: open an issue in this repository
- Roon Server product support: visit [Roon Labs Support](https://roon.app/support)
