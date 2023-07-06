# https://docs.fastly.com/signalsciences/install-guides/agent-installation/ubuntu-agent/
ARG BASE_IMAGE

# we're allowing the CI process to tag our image explicitly
# hadolint ignore=DL3006
FROM docker.io/library/${BASE_IMAGE}
ARG DEBIAN_FRONTEND=noninteractive
SHELL [ "/bin/bash", "-Eeuo", "pipefail", "-c" ]

# Don't want to pin apt package versions (yet... TODO perhaps)
# hadolint ignore=DL3008
RUN \
apt-get update; \
apt-get install --yes --no-install-recommends apt-transport-https wget gnupg ca-certificates; \
wget -qO - https://apt.signalsciences.net/release/gpgkey | gpg --dearmor -o /usr/share/keyrings/sigsci.gpg; \
echo "deb [signed-by=/usr/share/keyrings/sigsci.gpg] https://apt.signalsciences.net/release/ubuntu/ jammy main" > /etc/apt/sources.list.d/sigsci-release.list; \
apt-get update; \
apt-get install --yes --no-install-recommends sigsci-agent; \
apt-get clean; \
rm -rf /var/lib/apt/lists/*;

COPY entrypoint.sh /entrypoint.sh
COPY wait-for/wait-for /usr/local/bin/

ENTRYPOINT [ "/entrypoint.sh" ]
