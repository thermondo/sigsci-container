PYTHON_VERSION?=3.12
JAVA_VERSION?=21

all: lint general python
.PHONY: all

general:
	docker build \
		--pull \
		--tag "localhost/thermondo-sigsci" \
		--tag "ghcr.io/thermondo/sigsci" \
		--build-arg "BASE_IMAGE=debian:bookworm-slim" \
		--build-arg "APT_SOURCE=https://apt.signalsciences.net/release/debian/ bookworm main" \
		.
.PHONY: general

python:
	docker build \
		--pull \
		--tag "localhost/thermondo-sigsci:python-${PYTHON_VERSION}" \
		--tag "ghcr.io/thermondo/sigsci:python-${PYTHON_VERSION}" \
		--build-arg "BASE_IMAGE=python:${PYTHON_VERSION}-slim" \
		--build-arg "APT_SOURCE=https://apt.signalsciences.net/release/debian/ bookworm main" \
		.
.PHONY: python

java:
	docker build \
		--pull \
		--tag "localhost/thermondo-sigsci:jre-${JAVA_VERSION}" \
		--tag "ghcr.io/thermondo/sigsci:jre-${JAVA_VERSION}" \
		--build-arg "BASE_IMAGE=eclipse-temurin:${JAVA_VERSION}-jre-jammy" \
		--build-arg "APT_SOURCE=https://apt.signalsciences.net/release/ubuntu/ jammy main" \
		.
.PHONY: java

lint:
	hadolint Dockerfile
	shellcheck *.sh
.PHONY: lint

shell: general
	docker run --rm -it --env SIGSCI_STATUS=disabled localhost/thermondo-sigsci /bin/bash
.PHONY: shell
