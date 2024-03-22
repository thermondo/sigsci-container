# https://docs.fastly.com/en/ngwaf/installing-the-agent-on-ubuntu
# https://docs.fastly.com/en/ngwaf/installing-the-agent-on-debian
ARG BASE_IMAGE

# we're allowing the CI process to tag our image explicitly
# hadolint ignore=DL3006
FROM docker.io/library/${BASE_IMAGE}
LABEL org.opencontainers.image.source="https://github.com/thermondo/sigsci-container"
ARG DEBIAN_FRONTEND=noninteractive
SHELL [ "/bin/bash", "-Eeuo", "pipefail", "-c" ]

# sometimes we're working with a debian base image, sometimes we're working with an ubuntu base
# image. this requires customizing our APT source a little bit, which we can do via build args.
ARG APT_SOURCE

# Don't want to pin apt package versions (yet... TODO perhaps)
# hadolint ignore=DL3008
RUN \
apt-get update; \
apt-get install --yes --no-install-recommends \
    apt-transport-https curl gnupg ca-certificates tini; \
curl --silent --fail --show-error --location https://apt.signalsciences.net/release/gpgkey | gpg --dearmor -o /usr/share/keyrings/sigsci.gpg; \
echo "deb [signed-by=/usr/share/keyrings/sigsci.gpg] ${APT_SOURCE}" > /etc/apt/sources.list.d/sigsci-release.list; \
apt-get update; \
apt-get install --yes --no-install-recommends sigsci-agent; \
apt-get clean; \
rm -rf /var/lib/apt/lists/*;

COPY entrypoint.sh /entrypoint.sh

# tell tini to forward signals to ALL processes, not just the immediate child
# don't be fooled by the env variable name; this makes tini forward ALL signals
# to ALL processes.
ENV TINI_KILL_PROCESS_GROUP=1

ENTRYPOINT [ "/usr/bin/tini", "-vvv", "--", "/entrypoint.sh" ]
