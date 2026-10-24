FROM ubuntu:26.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    nginx \
    php-fpm \
    php-mysql \
    php-curl \
    php-gd \
    php-mbstring \
    php-xml \
    php-zip \
    supervisor \
    gettext-base \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# Redirect global Nginx configurations to read our non-root runtime file
RUN rm /etc/nginx/sites-enabled/default && \
    echo "include /tmp/nginx-runtime.conf;" > /etc/nginx/conf.d/rootless.conf
# Disable the log file inside the pool config so it logs to standard error stream instead
RUN sed -i 's|;catch_workers_output = yes|catch_workers_output = yes|g' /etc/php/8.5/fpm/pool.d/www.conf

# Adjust global PHP-FPM configuration to use /tmp for its socket
RUN sed -i 's|listen = /run/php/php8.5-fpm.sock|listen = /tmp/php8.5-fpm.sock|g' /etc/php/8.5/fpm/pool.d/www.conf
# FIX: Move PHP-FPM's main master PID and log file to writeable /tmp
RUN sed -i 's|;error_log = .*|error_log = /tmp/php8.5-fpm.log|g' /etc/php/8.5/fpm/php-fpm.conf && \
    sed -i 's|;pid = .*|pid = /tmp/php8.5-fpm.pid|g' /etc/php/8.5/fpm/php-fpm.conf
# Prevent PHP-FPM from trying to drop root privileges internally (since it's already non-root)
RUN sed -i 's/;daemonize = yes/daemonize = no/g' /etc/php/8.5/fpm/php-fpm.conf

# Forcefully comment out user and group switching directives
RUN sed -i 's/^user =/;user =/g' /etc/php/8.5/fpm/pool.d/www.conf
RUN sed -i 's/^group =/;group =/g' /etc/php/8.5/fpm/pool.d/www.conf

# Forcefully comment out socket listen permissions (not needed since we are running rootless in /tmp)
RUN sed -i 's/^listen.owner/;listen.owner/g' /etc/php/8.5/fpm/pool.d/www.conf
RUN sed -i 's/^listen.group/;listen.group/g' /etc/php/8.5/fpm/pool.d/www.conf


# Give the non-root 'www-data' user ownership over required system runtime folders
RUN chown -R www-data:www-data /var/lib/nginx /var/log/nginx /etc/nginx /var/run
RUN touch /var/log/nginx/access.log /var/log/nginx/error.log && \
    chown www-data:www-data /var/log/nginx/access.log /var/log/nginx/error.log

# Copy our configuration templates to /tmp where they can be accessed/modified by non-root
COPY --chown=www-data:www-data supervisord.conf /tmp/supervisord.conf
COPY --chown=www-data:www-data nginx.conf.template /tmp/nginx.conf.template
COPY --chown=www-data:www-data entrypoint.sh /tmp/entrypoint.sh


RUN echo "[www]\n\
listen = /tmp/php8.5-fpm.sock\n\
pm = dynamic\n\
pm.max_children = 5\n\
pm.start_servers = 2\n\
pm.min_spare_servers = 1\n\
pm.max_spare_servers = 3" > /etc/php/8.5/fpm/pool.d/www.conf
# Force the main system daemon to log directly to stdout/stderr instead of a root-owned file
RUN sed -i 's|error_log = .*|error_log = /dev/stderr|g' /etc/php/8.5/fpm/php-fpm.conf

# 1. Force Nginx's global PID tracker to use /tmp instead of /var/run/
RUN sed -i 's|pid .*|pid /tmp/nginx.pid;|g' /etc/nginx/nginx.conf

# 2. Force PHP-FPM's global master log file to use /tmp
RUN sed -i 's|error_log = .*|error_log = /tmp/php8.5-fpm.log|g' /etc/php/8.5/fpm/php-fpm.conf

# 3. Ensure the environment path is fully open to the execution user
RUN mkdir -p /var/lib/nginx && chown -R www-data:www-data /var/lib/nginx

RUN chmod +x /tmp/entrypoint.sh
# EXPOSE the new unprivileged port
EXPOSE 8080

# Switch permanently to the non-root user
USER www-data

ENTRYPOINT ["/tmp/entrypoint.sh"]
