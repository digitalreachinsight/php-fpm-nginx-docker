FROM ubuntu:26.04

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install Nginx, PHP-FPM, Supervisor, and WordPress PHP extensions
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
    && rm -rf /var/lib/apt/lists/*

# Configure PHP-FPM to use a Unix socket and run in the foreground
RUN mkdir -p /run/php && \
    sed -i 's/;listen.mode = 0660/listen.mode = 0660/g' /etc/php/8.3/fpm/pool.d/www.conf && \
    clearabs=$(grep -n "listen =" /etc/php/8.3/fpm/pool.d/www.conf | cut -d: -f1)

# Copy configuration files into the image
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY nginx.conf /etc/nginx/sites-available/default

# Set up the WordPress working directory
WORKDIR /var/www/html

# Expose port 80 for cluster routing meshes / ingress controllers
EXPOSE 80

# Start Supervisor to manage both Nginx and PHP-FPM
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
