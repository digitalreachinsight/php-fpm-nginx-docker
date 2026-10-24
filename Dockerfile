FROM ubuntu:26.04

ENV DEBIAN_FRONTEND=noninteractive

# Added gettext-base for the envsubst utility
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

RUN mkdir -p /run/php && \
    sed -i 's/;listen.mode = 0660/listen.mode = 0660/g' /etc/php/8.3/fpm/pool.d/www.conf

# Copy configurations and the template
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY nginx.conf.template /etc/nginx/nginx.conf.template

# Copy and set up the entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80

# The container now boots using the entrypoint script
ENTRYPOINT ["/entrypoint.sh"]
