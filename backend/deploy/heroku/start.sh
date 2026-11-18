#!/bin/bash
set -uo pipefail

# Preserve one-off commands (for example, the question importer).
if (( $# )); then exec "$@"; fi
: "${PORT:?Heroku must supply PORT}"
if [[ ! "$PORT" =~ ^[0-9]+$ ]] || (( PORT < 1 || PORT > 65535 || PORT == 8081 || PORT == 3000 )); then
    echo 'PORT must be a valid port distinct from internal ports 8081 and 3000' >&2
    exit 1
fi

# Only PORT is substituted: nginx variables and Config Var secrets stay intact.
envsubst '${PORT}' < /app/nginx.conf.template > /tmp/skillbattles-nginx.conf
nginx -t -c /tmp/skillbattles-nginx.conf || exit 1
children=()
shutdown() {
    trap '' TERM INT
    kill -TERM "${children[@]}" 2>/dev/null || true
    wait "${children[@]}" 2>/dev/null || true
}
trap 'shutdown; exit 143' TERM INT

java -Xms64m -Xmx224m -Xss512k -XX:MaxMetaspaceSize=128m \
    -XX:ReservedCodeCacheSize=48m -XX:MaxDirectMemorySize=32m \
    -XX:ActiveProcessorCount=2 -XX:+ExitOnOutOfMemoryError \
    -Duser.timezone=UTC -jar /app/app.jar \
    --server.address=127.0.0.1 --server.port=8081 &
children+=("$!")
PORT=3000 /app/app &
children+=("$!")
nginx -c /tmp/skillbattles-nginx.conf -g 'daemon off;' &
children+=("$!")

wait -n "${children[@]}"
status=$?
shutdown
# A child stopping unexpectedly must trigger a dyno restart, even on exit 0.
if (( status == 0 )); then status=1; fi
exit "$status"
