all: basic python
.PHONY: all

basic:
	docker build \
		--pull \
		--tag "localhost/thermondo-sigsci" \
		--tag "ghcr.io/thermondo/sigsci" \
		--build-arg "BASE_IMAGE=ubuntu:22.04" \
		.
.PHONY: basic

python:
	docker build \
		--pull \
		--tag "localhost/thermondo-sigsci:python-${PYTHON_VERSION}" \
		--tag "ghcr.io/thermondo/sigsci:python-${PYTHON_VERSION}" \
		--build-arg "BASE_IMAGE=python:${PYTHON_VERSION}-slim" \
		.
.PHONY: python
