#!/bin/bash
# Huly gateway on Railway: nginx on Railway's injected port in front of the web client and the five public paths, plus a bootstrap
# that creates the first account and its workspace from variables, so the deploy form is empty and sign-up can stay closed.
set -eu
for v in SECRET CR_PASSWORD MINIO_ROOT_USER MINIO_ROOT_PASSWORD ADMIN_EMAIL ADMIN_PASSWORD; do
  eval "[ -n \"\${$v:-}\" ]" || { echo "[huly] ERROR: $v is not set" >&2; exit 1; }
done

mkdir -p /tmp/nginx
PORT="${PORT:-8080}"
export PORT
RESOLVER="$(awk '/^nameserver/ {print $2; exit}' /etc/resolv.conf 2>/dev/null || true)"
[ -n "$RESOLVER" ] || RESOLVER="fd12::10"
case "$RESOLVER" in *:*) RESOLVER="[$RESOLVER]" ;; esac
export RESOLVER
envsubst '${PORT} ${RESOLVER}' < /etc/nginx/huly.conf.template > /tmp/nginx/nginx.conf
nginx -t -c /tmp/nginx/nginx.conf

nginx -c /tmp/nginx/nginx.conf &
NGINX_PID=$!
/usr/local/bin/huly-bootstrap.sh &

# nginx is the service: if it dies the deploy must fail; the bootstrap ends by itself once the account and workspace exist.
wait "$NGINX_PID"
