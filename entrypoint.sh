#!/bin/sh

if [ -z "$WEB_ROOT" ]; then
  export WEB_ROOT="/tmp/html"
fi

mkdir -p "$WEB_ROOT"

# Process the template
envsubst '${WEB_ROOT}' < /tmp/nginx.conf.template > /tmp/nginx-runtime.conf

# DEBUG CHECK: Print out Nginx validation errors directly to docker log
/usr/sbin/nginx -t -c /etc/nginx/nginx.conf

# Start Supervisor
exec /usr/bin/supervisord -c /tmp/supervisord.conf
