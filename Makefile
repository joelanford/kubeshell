SHELL := /bin/bash

KUBECTL_VERSION := 1.9.3
DOCKER_VERSION  := 17.03.2-ce

APP_NAME     := kubeshell
DOCKER_REPO  := joelanford
DOCKER_IMAGE := $(DOCKER_REPO)/$(APP_NAME)

VERSION    := $(shell git describe --always --dirty)
GIT_HASH   ?= $(shell git rev-parse HEAD)
GIT_BRANCH ?= $(shell git rev-parse --abbrev-ref HEAD)

USER       ?= $(USERNAME)

.PHONY: all
all: image

.PHONY: info
info:
	@echo "DOCKER_IMAGE: ${DOCKER_IMAGE}"
	@echo "VERSION:      ${VERSION}"
	@echo "GIT_HASH:     ${GIT_HASH}"
	@echo "GIT_BRANCH:   ${GIT_BRANCH}"
	@echo "USER:         ${USER}"

.PHONY: image
image: GOOS := linux
image:
	docker build -f Dockerfile \
                     --build-arg KUBECTL_VERSION=${KUBECTL_VERSION} \
                     --build-arg DOCKER_VERSION=${DOCKER_VERSION} \
                     --build-arg GIT_COMMIT=${GIT_HASH} \
                     -t ${DOCKER_IMAGE}:${VERSION} .

.PHONY: push
push:
	@if [[ ${GIT_BRANCH} == feature/* ]]; then \
		echo "Skipping push for feature branch \"${GIT_BRANCH}\""; \
	elif [[ ${VERSION} == *-dirty ]]; then \
		echo "Skipping push for dirty version \"${VERSION}\""; \
	else \
		docker push ${DOCKER_IMAGE}:${VERSION}; \
		EXTRA_IMAGE_TAG=""; \
		if [[ ${GIT_BRANCH} == "develop" ]]; then \
			EXTRA_IMAGE_TAG=alpha; \
		elif [[ ${GIT_BRANCH} == release/* ]]; then \
			EXTRA_IMAGE_TAG=beta; \
		elif [[ ${GIT_BRANCH} == "master" ]]; then \
			EXTRA_IMAGE_TAG=latest; \
		fi; \
		if [[ -n "$${EXTRA_IMAGE_TAG}" ]]; then \
			echo docker tag ${DOCKER_IMAGE}:${VERSION} ${DOCKER_IMAGE}:$${EXTRA_IMAGE_TAG}; \
			docker tag ${DOCKER_IMAGE}:${VERSION} ${DOCKER_IMAGE}:$${EXTRA_IMAGE_TAG}; \
			echo docker push ${DOCKER_IMAGE}:$${EXTRA_IMAGE_TAG}; \
			docker push ${DOCKER_IMAGE}:$${EXTRA_IMAGE_TAG}; \
		fi; \
	fi

.PHONY: version
version:
	@echo ${VERSION}	

.PHONY: clean
clean:
	rm -f ${APP_NAME}
	docker rmi -f `docker images | grep ${DOCKER_IMAGE} | awk '{print $$3}'` 2>/dev/null || true
