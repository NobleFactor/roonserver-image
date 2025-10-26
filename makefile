########################################################################################################################
# Noble Factor Roon Server Makefile
# Copyright (c) 2024 Noble Factor
# SPDX-License-Identifier: MIT AND LicenseRef:Roon-software-terms-and-conditions
########################################################################################################################

# TODO (DANOBLE): Reference SPDX document that references MIT and Roon software terms and conditions.

# Use bash for recipes and enable strict mode
SHELL := /usr/bin/env bash
.SHELLFLAGS := -o errexit -o nounset -o pipefail -c

define USAGE
NAME
    roonserver-image Makefile - build and manage a Roon Server container (Linux)

SYNOPSIS
    make [VARIABLE=value ...] TARGET

DESCRIPTION
    This Makefile builds the Roon Server container image and manages its lifecycle using Docker and Docker Compose.
    It is intended for Linux amd64 hosts. macOS users should consider installing Roon Server as a system launch daemon
    (see tools/Darwin/Install-RoonServer) as containerized mDNS on macOS/Windows is unreliable.

TARGETS
    help
        Print this help and exit.

    clean
        Alias for Clean-Project.

    Clean-Project
        Remove the Roon Server container and image (ignores errors if not present).

    Clean-System
        Run docker system prune and volume prune (after Clean-Project).

    New-RoonServer
        Build the Roon Server image using buildx for linux/amd64 with build args:
        roon_dataroot, roon_serverroot, roon_user.

    New-RoonServerContainer
        Create the container via docker compose (no build). If macvlan driver is configured, ensures a network exists.
        Requires IP_RANGE to be set to the CIDR used for the macvlan network.

    Start-RoonServer
        Ensure user directories exist (~/Documents/Roon/{Backup,Data,Music}) and start the container.

    Stop-RoonServer
        Stop the container via docker compose.

    Restart-RoonServer
        Restart the container via docker compose.

    Start-RoonServerShell
        Open an interactive shell inside the running container.

ENVIRONMENT / VARIABLES
    DOCKER_NAMESPACE             Default: noblefactor
    DOCKER_REPOSITORY            Default: roonserver
    DOCKER_TAG                   Default: 1.0.0-preview.2
    DOCKER_IMAGE_ROONSERVER      Computed: $$(DOCKER_NAMESPACE)/$$(DOCKER_REPOSITORY):$$(DOCKER_TAG)

    DOCKER_COMPOSE_PROJECT_NAME  Default: roonserver
    DOCKER_CONTAINER_NAME        Computed: $$(DOCKER_COMPOSE_PROJECT_NAME)-service

    ROON_SERVERROOT              Default: /opt/local/share/roon/roonserver
    ROON_DATAROOT                Default: /opt/local/var/roon
    ROON_USER                    Default: roon

    IP_RANGE                     Required CIDR used by New-RoonServerContainer when creating a macvlan network (Linux only).
                                 Ensure your DHCP server allows this range.

FILES
    compose.yaml
    Dockerfile
    assets/Install-RoonServer
    assets/Start-AvahiDaemon
    assets/roonserver-service

EXAMPLES
    Build the image:
        make New-RoonServer

    Build the container:
        make New-RoonServerContainer IP_RANGE=192.168.1.8/29  # CIDR for the macvlan network (ensure your DHCP server allows this range)

    Start the container:
        make Start-RoonServer

    Open a shell in the running container:
        make Start-RoonServerShell

SEE ALSO
    docker(1), docker-buildx(1), docker-compose(1)
endef

export USAGE

###########
# VARIABLES
###########

PROJECT_ROOT := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

# Docker image variables

DOCKER_NAMESPACE := noblefactor
DOCKER_REPOSITORY := roonserver
DOCKER_TAG := 1.0.0-preview.2

export DOCKER_IMAGE_ROONSERVER := $(DOCKER_NAMESPACE)/$(DOCKER_REPOSITORY):$(DOCKER_TAG)

# Docker compose variables

export DOCKER_COMPOSE_PROJECT_NAME := roonserver

export DOCKER_CONTAINER_NAME := $(DOCKER_COMPOSE_PROJECT_NAME)-service
export ROON_SERVERROOT := /opt/local/share/roon/roonserver
export ROON_DATAROOT := /opt/local/var/roon
export ROON_USER := roon

## External networking environment 

export IP_RANGE

ifeq ($(shell uname -s),Linux)
	network_device := $(shell ip route | awk '/^default / { print $$5; exit }')
	network_driver := macvlan
	network_name := $(DOCKER_COMPOSE_PROJECT_NAME)-$(network_device)
else
	undefine network_device
	undefine network_driver
	undefine network_name
endif

###########
# TARGETS
###########

.PHONY: help clean Clean-Project Clean-System New-RoonServer Start-RoonServer Stop-RoonServer Restart-RoonServer Start-RoonServerShell

help:
	@echo "$$USAGE" | less 1>&2

clean: Clean-Project

Clean-Project:
	-docker container rm --force $(DOCKER_CONTAINER_NAME) >/dev/null 2>&1 || true
	-docker image rm --force $(DOCKER_IMAGE_ROONSERVER) >/dev/null 2>&1 || true
	@if [[ -n "$(network_name)" ]]; then \
		docker network rm "$(network_name)" >/dev/null 2>&1 || true; \
	fi

Clean-System: Clean-Project
	docker system prune --force \
	&& docker volume prune --force

New-RoonServer:
	docker buildx build --platform linux/amd64 --tag $(DOCKER_IMAGE_ROONSERVER) $(PROJECT_ROOT) --progress=plain \
		--build-arg roon_dataroot="$(ROON_DATAROOT)" \
		--build-arg roon_serverroot="$(ROON_SERVERROOT)" \
		--build-arg roon_user="$(ROON_USER)"

New-RoonServerContainer:
	# Ensure macvlan is supported and required vars are set (shell checks to avoid make-time conditionals in recipes)
	@set -e; \
	if [[ "$$(uname -s)" != "Linux" ]]; then \
		echo "Docker macvlan requires a Linux host (got $$(uname -s))" 1>&2; exit 2; \
	fi; \
	if [[ -z "$(IP_RANGE)" ]]; then \
		echo "IP_RANGE is required (CIDR, e.g., 192.168.1.0/24)" 1>&2; exit 2; \
	fi; \
	if docker network inspect $(network_name) >/dev/null 2>&1; then \
		driver="$$(docker network inspect -f '{{ .Driver }}' $(network_name) 2>/dev/null)"; \
		if [[ "$$driver" != "macvlan" ]]; then \
			echo "Network '$(network_name)' exists with driver '"$$driver"' (expected 'macvlan')" 1>&2; exit 2; \
		fi; \
		echo "[=] Using existing macvlan network '$(network_name)'"; \
	else \
		echo "[+] Creating macvlan network '$(network_name)' parent '$(network_device)' subnet '$(IP_RANGE)'"; \
		docker network create -d macvlan -o parent=$(network_device) --subnet=$(IP_RANGE) $(network_name); \
	fi; \
	MACVLAN_NETWORK_NAME="$(network_name)" docker compose create --no-build --remove-orphans

Restart-RoonServer:
	docker compose restart

Start-RoonServer:
	mkdir -p ~/Documents/Roon/{Backup,Data,Music} \
	&& docker compose start

Start-RoonServerShell:
	docker exec --interactive --tty $(DOCKER_CONTAINER_NAME) /bin/bash

Stop-RoonServer:
	docker compose stop
