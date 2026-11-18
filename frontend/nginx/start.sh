#!/bin/bash
# Runs the Jaspr server (pages) and nginx (TLS, static files, proxies) in one
# container. The container stops when either process exits, so the restart
# policy brings both back.
set -uo pipefail

PORT=3000 /app/app &
/docker-entrypoint.sh nginx -g 'daemon off;' &

trap 'kill -TERM $(jobs -p) 2>/dev/null' TERM INT

wait -n
status=$?
kill -TERM $(jobs -p) 2>/dev/null
wait
exit "$status"
