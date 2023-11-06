#!/usr/bin/env bash
# shellcheck disable=SC2317  # shellcheck thinks our trap has unreachable code
#
# usage: ./entrypoint.sh <the command to execute>
#
# this script performs the following steps:
#
# 1. run the given command as a background job
# 2. wait for an HTTP response at `SIGSCI_WAIT_ENDPOINT`
# 3. run the sigsci agent, forwarding requests from `PORT` to `APP_PORT`
#
# however if the `SIGSCI_STATUS` environment variable is set to `disabled`
# then this script will just execute step 1 only.
#
# SIGINT, SIGTERM signals that this process receives will be forwarded to
# the child process.
#

set -Eeuo pipefail

log() {
    echo "SIGSCI: ${*}"
}

if [ "${#}" -eq 0 ]; then
    log "FATAL: no command specified."
    exit 1
fi

# check if sigsci is disabled. if so, just execute the command and be done with it!
SIGSCI_STATUS="${SIGSCI_STATUS:-enabled}"
if [ "${SIGSCI_STATUS}" == "disabled" ]; then
    if [ "${PORT:-}" != "" ]; then
        # we still expect our container to listen on ${PORT}, but since we're not running the
        # sigsci agent, we need to tell the upstream app to run on that port instead.
        export APP_PORT="${PORT}"
    fi

    # `exec` replaces this shell with the given command. this makes it so we don't need to
    # worry about forwarding signals to the child process, because the child process will
    # just get those signals directly.
    exec "${@}"
    exit ${?}
fi

APP_PORT="${APP_PORT:-2000}"

if [ "${APP_PORT}" -eq "${PORT}" ]; then
    log "FATAL: PORT env variable is set to ${PORT}, which is reserved for the upstream application."
    log "Consider changing APP_PORT env variable to something that won't conflict."
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

# start child process in the background, save its PID so we can forward
# signals to it
"${@}" &
CHILD_PID=${!}

# trap various signals and forward them to the child process so it can
# gracefully shutdown if needed
on_signal_received() {
    local signal_name="${1}"
    kill -s "${signal_name}" "${CHILD_PID}"
    wait "${CHILD_PID}" || true
}
trap 'on_signal_received SIGTERM' SIGTERM
trap 'on_signal_received SIGINT' SIGINT

# now that the child process is running, let's spam it with HTTP requests
# until we get a response
UPSTREAM_URL="http://127.0.0.1:${APP_PORT}/${SIGSCI_WAIT_ENDPOINT:-}"
log "waiting for ${UPSTREAM_URL} to respond..."

send_upstream_request() {
    curl --silent --output /dev/null \
        --max-time 2 \
        "${UPSTREAM_URL}"
}

wait_for_response() {
    local timeout="${SIGSCI_WAIT_TIMEOUT:-60}"
    local timeout_end=$(($(date +%s) + timeout))

    while ! send_upstream_request; do
        if [ "${timeout}" -ne 0 ] && [ "$(date +%s)" -ge "${timeout_end}" ]; then
            log "${UPSTREAM_URL} failed to respond after ${timeout} seconds."
            exit 1
        fi
        sleep 1
    done
}

wait_for_response

# child process is running and responding to HTTP requests. almost done!
log "starting sigsci-agent..."
/usr/sbin/sigsci-agent --config "${CONFIG_FILE}" &

# wait for ANY background job to exit; either the child process or the sigsci agent.
# if just one of them exits, we allow the whole container to exit.
wait -n
exit ${?}
