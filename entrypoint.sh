#!/bin/sh

if [ -z "$WEB_ROOT" ]; then
  export WEB_ROOT="/tmp/html"
fi

mkdir -p "$WEB_ROOT"

# Processes the template file cleanly as a non-root user
envsubst '${WEB_ROOT}' < /tmp/nginx.conf.template > /tmp/nginx-runtime.conf

exec /usr/bin/supervisord -c /tmp/supervisord.conf
