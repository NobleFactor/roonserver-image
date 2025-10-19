########################################################################################################################
# Noble Factor Roon Server Makefile
# Copyright (c) 2024 Noble Factor
# SPDX-License-Identifier: MIT AND LicenseRef:Roon-software-terms-and-conditions
########################################################################################################################

# This Makefile provides convenient targets for building, running, and managing the Roon Server container image and its
# lifecycle. It is designed for use on macOS (OrbStack or Docker Desktop) and Linux hosts.
#
# See the README.md for detailed usage and configuration notes.

# TODO (DANOBLE): Reference SPDX document that references MIT and Roon software terms and conditions.

PROJECT_ROOT := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))$(PROJECT_ROOT)
DOCKER_NAMESPACE := noblefactor
DOCKER_REPOSITORY := roonserver
DOCKER_TAG := 1.0.0-preview.2
DOCKER_CONTAINER := $(DOCKER_REPOSITORY)

export IMAGE := $(DOCKER_NAMESPACE)/$(DOCKER_REPOSITORY):$(DOCKER_TAG)

define USAGE
Usage: make TARGET

Targets:

	help                  Display this text and exit
	clean                 Remove the Roon Server container and image
	New-RoonServer        Build the Docker image and create the container (no start)
	Start-RoonServer      Start the Roon Server container (creates data/music/backup dirs if needed)
	Stop-RoonServer       Stop the Roon Server container
	Restart-RoonServer    Restart the Roon Server container
	Start-RoonServerShell Open a shell in the running Roon Server container

Notes:

- The default data, music, and backup directories are under ~/Documents/Roon/ on macOS.
- See README.md and docker-compose.yml for more information.
endef

export USAGE

help:
	@echo 1>&2 "$$USAGE"

clean:
	docker container rm --force $(DOCKER_CONTAINER) 2> /dev/null \
	&& docker image rm --force $(DOCKER_NAMESPACE)/$(DOCKER_REPOSITORY):$(DOCKER_TAG) 2> /dev/null

New-RoonServer:
	docker buildx build --platform linux/amd64 --tag $(IMAGE) $(PROJECT_ROOT) --progress=plain \
	&& docker compose --project-name $(DOCKER_REPOSITORY) create --no-build --remove-orphans

Restart-RoonServer:
	docker compose --project-name $(DOCKER_REPOSITORY) restart

Start-RoonServer:
	mkdir -p ~/Documents/Roon/{Backup,Data,Music} \
	&& docker compose --project-name $(DOCKER_REPOSITORY) start

Start-RoonServerShell:
	docker exec --interactive --tty $(DOCKER_CONTAINER) /bin/bash

Stop-RoonServer:
	docker compose --project-name $(DOCKER_REPOSITORY) stop
