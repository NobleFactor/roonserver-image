#################################################
# Copyright (c) 2024 Noble Factor
# SPDX Document reference
#############################################

# TODO (DANOBLE) Reference SPDX document that references MIT and Roon software terms and conditions.

PROJECT_ROOT := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))$(PROJECT_ROOT)
DOCKER_NAMESPACE := noblefactor
DOCKER_REPOSITORY := roonserver
DOCKER_TAG := 1.0.0-preview.1
DOCKER_CONTAINER := $(DOCKER_REPOSITORY)

export IMAGE := $(DOCKER_NAMESPACE)/$(DOCKER_REPOSITORY):$(DOCKER_TAG)

image:
	docker buildx build --platform linux/amd64 --tag $(IMAGE) $(PROJECT_ROOT)

container: image
	docker compose --project-name $(DOCKER_REPOSITORY) create --no-build --remove-orphans

clean:
	docker container rm --force $(DOCKER_CONTAINER)
	docker image rm --force $(DOCKER_NAMESPACE)/$(DOCKER_REPOSITORY):$(DOCKER_TAG)
