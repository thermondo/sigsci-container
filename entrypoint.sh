#!/usr/bin/env bash
set -Eeuo pipefail

if [ "${#}" -eq 0 ]; then
    echo "FATAL: no command specified."
    exit 1
fi

APP_PORT="${APP_PORT:-2000}"

if [ "${APP_PORT}" -eq "${PORT}" ]; then
    echo "FATAL: PORT env variable is set to ${PORT}, which is reserved for the upstream application."
    echo "Consider changing APP_PORT env variable to something that won't conflict."
    exit 1
fi

# sigsci configuration docs:
#
#     https://docs.fastly.com/signalsciences/install-guides/agent-config/
#     https://docs.fastly.com/signalsciences/install-guides/reverse-proxy/
#

# we save config in a temp file because this script may (should?) not have root privileges.
# so the default /etc/sigsci/agent.conf location won't work.
CONFIG_FILE="$(mktemp)"

echo "
accesskeyid = \"${SIGSCI_ACCESSKEYID}\"
secretaccesskey = \"${SIGSCI_SECRETACCESSKEY}\"

[revproxy-listener.APP]
listener = \"http://0.0.0.0:${PORT}\"
upstreams = \"http://127.0.0.1:${APP_PORT}\"
" > "${CONFIG_FILE}"

"${@}" &

UPSTREAM_URL="http://127.0.0.1:${APP_PORT}/${SIGSCI_WAIT_ENDPOINT:-}"
echo "waiting for ${UPSTREAM_URL} to respond..."

send_upstream_request() {
    curl --silent --fail --output /dev/null \
        --max-time 2 \
        "${UPSTREAM_URL}"
}

wait_for_response() {
    local timeout="${SIGSCI_WAIT_TIMEOUT:-60}"
    local timeout_end=$(($(date +%s) + timeout))

    while ! send_upstream_request; do
        if [ "${timeout}" -ne 0 ] && [ "$(date +%s)" -ge "${timeout_end}" ]; then
            echo "${UPSTREAM_URL} failed to respond after ${timeout} seconds."
            exit 1
        fi
        sleep 1
    done
}

wait_for_response

echo "starting sigsci-agent..."
/usr/sbin/sigsci-agent --config "${CONFIG_FILE}" &

wait -n
exit ${?}
