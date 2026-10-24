#!/bin/sh

# 1. Fallback to a default path if WEB_ROOT is not set by the user
if [ -z "$WEB_ROOT" ]; then
  export WEB_ROOT="/var/www/html"
fi

# 2. Make sure the target directory actually exists
mkdir -p "$WEB_ROOT"

# 3. Swap ${WEB_ROOT} in the template and write it to Nginx's active config folder
envsubst '${WEB_ROOT}' < /etc/nginx/nginx.conf.template > /etc/nginx/sites-available/default

# 4. Hand over control to Supervisor to launch Nginx and PHP-FPM
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
