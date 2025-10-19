#!/usr/bin/env bash

# First, ensure you're on the master branch
git checkout master

# Create a new orphan branch (starts with no history)
git checkout --orphan new-master

# Stage all files
git add -A

# Create the initial commit with the message below
git commit -m "Initial commit: Roon Server Docker image

This project provides a Docker image for running Roon Server in a container,
with automatic installation and configuration on first run.

Key Features:
- Automatic Roon Server installation and configuration via install-roonserver script
- Container-aware deployment (detects Docker vs bare metal)
- Supports both Docker Compose and standalone Docker CLI usage
- Make-based workflow for simplified container lifecycle management
- Developed and tested on macOS with OrbStack
- Ubuntu-based image with all required dependencies

Architecture:
- Custom installation script with idempotent behavior
- Separate server and data directories to prevent update issues
- Systemd service management for bare metal deployments
- Volume mounts for data, music, and backup directories

Directory Structure:
- ROON_SERVERROOT: /opt/local/share/roon/roonserver (application files)
- ROON_DATAROOT: /opt/local/var/roon (data, music, backups)

Project Structure:
- Dockerfile: Ubuntu-based image with Roon Server dependencies
- docker-compose.yml: Simplified bind mount configuration
- makefile: Comprehensive targets for build, start, stop, shell access
- assets/install-roonserver: Installation and startup script
- assets/uninstall-roonserver: Cleanup script
- README.md: Complete documentation with Quick Start and examples
- LICENSE.md: MIT license with Roon Labs terms reference

Development Environment:
- Designed for macOS with OrbStack (Docker Desktop alternative)
- Best tested using Roon Remote app from iPad/iPhone
- Includes file access authorization flow for macOS

Usage:
  make help              # Display available commands
  make New-RoonServer    # Build image and create container
  make Start-RoonServer  # Start the Roon Server

See README.md for complete documentation and configuration options.

Copyright (c) 2024 Noble Factor
SPDX-License-Identifier: MIT AND LicenseRef:Roon-software-terms-and-conditions"

# Delete the old master branch
git branch -D master

# Rename the new orphan branch to master
git branch -m master

# Force push to remote (WARNING: This rewrites history!)
git push -f origin master
