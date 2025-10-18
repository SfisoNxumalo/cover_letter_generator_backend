# Use official PHP image with Apache
FROM php:8.3-apache

# Set working directory
WORKDIR /var/www/html

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    curl && \
    docker-php-ext-install pdo pdo_mysql mbstring exif pcntl bcmath gd

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Set Apache DocumentRoot to Laravel public
RUN sed -i 's|/var/www/html|/var/www/html/public|g' /etc/apache2/sites-available/000-default.conf

# Allow .htaccess overrides
RUN echo '<Directory /var/www/html/public>\n\
    Options Indexes FollowSymLinks\n\
    AllowOverride All\n\
    Require all granted\n\
</Directory>' > /etc/apache2/conf-available/laravel.conf \
    && a2enconf laravel

# Copy composer from official composer image
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Copy project files
COPY . .

# Install dependencies
RUN composer install --no-dev --optimize-autoloader

# Set correct permissions for Laravel
RUN chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# Copy example env to actual env
RUN cp .env.example .env
# Create entrypoint script for Render
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
echo "Starting Laravel application on Render..."\n\
\n\
# Create minimal .env file from Render environment variables\n\
cat > .env << EOF\n\
APP_NAME="${APP_NAME:-Laravel}"\n\
APP_ENV="${APP_ENV:-production}"\n\
APP_KEY="${APP_KEY:-base64:$(openssl rand -base64 32)}"\n\
APP_DEBUG="${APP_DEBUG:-false}"\n\
APP_URL="${APP_URL:-http://localhost}"\n\
\n\
LOG_CHANNEL="${LOG_CHANNEL:-stack}"\n\
LOG_DEPRECATIONS_CHANNEL=null\n\
LOG_LEVEL="${LOG_LEVEL:-error}"\n\
\n\
# No database - use array driver\n\
DB_CONNECTION=array\n\
\n\
# Use array/file drivers (no database needed)\n\
BROADCAST_DRIVER=log\n\
CACHE_DRIVER=array\n\
FILESYSTEM_DISK=local\n\
QUEUE_CONNECTION=sync\n\
SESSION_DRIVER=array\n\
SESSION_LIFETIME=120\n\
\n\
# OpenAI Configuration\n\
OPENAI_API_KEY="${OPENAI_API_KEY}"\n\
OPENAI_ORGANIZATION="${OPENAI_ORGANIZATION:-}"\n\
EOF\n\
\n\
echo ".env file created successfully"\n\
\n\
# Set final permissions\n\
chown -R www-data:www-data storage bootstrap/cache\n\
chmod -R 775 storage bootstrap/cache\n\
\n\
echo "Laravel application ready!"\n\
echo "OpenAI API Key configured: ${OPENAI_API_KEY:0:10}..."\n\
\n\
# Start Apache\n\
exec apache2-foreground\n\
' > /usr/local/bin/docker-entrypoint.sh && chmod +x /usr/local/bin/docker-entrypoint.sh


# Disable database requirement by using file-based sessions
RUN sed -i "s/DB_CONNECTION=.*/DB_CONNECTION=sqlite/" .env \
    && sed -i "s/DB_DATABASE=.*/DB_DATABASE=\/tmp\/laravel.sqlite/" .env \
    && sed -i "s/SESSION_DRIVER=.*/SESSION_DRIVER=file/" .env \
    && sed -i "s/CACHE_DRIVER=.*/CACHE_DRIVER=file/" .env \
    && sed -i "s/QUEUE_CONNECTION=.*/QUEUE_CONNECTION=sync/" .env

# Generate app key
RUN php artisan key:generate

# Optimize Laravel
RUN php artisan config:cache && php artisan route:cache && php artisan view:cache

# RUN --mount=type=secret,id=_env,dst=/etc/secrets/.env cat /etc/secrets/.env

# Ensure storage/framework/sessions exists
RUN mkdir -p storage/framework/sessions \
    && chown -R www-data:www-data storage/framework/sessions \
    && chmod -R 775 storage/framework/sessions

# Expose port 80
EXPOSE 80

# Start Apache server
CMD ["apache2-foreground"]
