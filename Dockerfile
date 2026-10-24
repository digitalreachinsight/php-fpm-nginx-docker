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
    && rm -rf /var/lib/apt/lists/*

# Redirect global Nginx configurations to read our non-root runtime file
RUN rm /etc/nginx/sites-enabled/default && \
    echo "include /tmp/nginx-runtime.conf;" > /etc/nginx/conf.d/rootless.conf

# Adjust global PHP-FPM configuration to use /tmp for its socket
RUN sed -i 's|listen = /run/php/php8.5-fpm.sock|listen = /tmp/php8.5-fpm.sock|g' /etc/php/8.5/fpm/pool.d/www.conf

# Give the non-root 'www-data' user ownership over required system runtime folders
RUN chown -R www-data:www-data /var/lib/nginx /var/log/nginx /etc/nginx

# Copy our configuration templates to /tmp where they can be accessed/modified by non-root
COPY --chown=www-data:www-data supervisord.conf /tmp/supervisord.conf
COPY --chown=www-data:www-data nginx.conf.template /tmp/nginx.conf.template
COPY --chown=www-data:www-data entrypoint.sh /tmp/entrypoint.sh

RUN chmod +x /tmp/entrypoint.sh

# EXPOSE the new unprivileged port
EXPOSE 8080

# Switch permanently to the non-root user
USER www-data

ENTRYPOINT ["/tmp/entrypoint.sh"]
