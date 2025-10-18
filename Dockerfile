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
    docker-php-ext-install pdo pdo_mysql mbstring exif pcntl bcmath gd && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

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

# Create required directories and set permissions
RUN mkdir -p storage/framework/sessions storage/framework/views storage/framework/cache storage/logs \
    && chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# Create entrypoint script for Render
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
echo "Starting Laravel application on Render..."\n\
\n\
# Create .env file from Render environment variables\n\
if [ ! -f .env ]; then\n\
    echo "Creating .env file from environment variables..."\n\
    cat > .env << EOF\n\
APP_NAME="${APP_NAME:-Laravel}"\n\
APP_ENV="${APP_ENV:-production}"\n\
APP_KEY="${APP_KEY}"\n\
APP_DEBUG="${APP_DEBUG:-false}"\n\
APP_URL="${APP_URL:-http://localhost}"\n\
\n\
LOG_CHANNEL="${LOG_CHANNEL:-stack}"\n\
LOG_LEVEL="${LOG_LEVEL:-error}"\n\
\n\
DB_CONNECTION="${DB_CONNECTION:-sqlite}"\n\
DB_DATABASE="${DB_DATABASE:-/tmp/laravel.sqlite}"\n\
\n\
SESSION_DRIVER="${SESSION_DRIVER:-file}"\n\
SESSION_LIFETIME="${SESSION_LIFETIME:-120}"\n\
\n\
CACHE_DRIVER="${CACHE_DRIVER:-file}"\n\
QUEUE_CONNECTION="${QUEUE_CONNECTION:-sync}"\n\
\n\
# OpenAI Configuration\n\
OPENAI_API_KEY="${OPENAI_API_KEY}"\n\
OPENAI_ORGANIZATION="${OPENAI_ORGANIZATION:-}"\n\
EOF\n\
fi\n\
\n\
# Generate app key if not set\n\
if [ -z "$APP_KEY" ] || ! grep -q "APP_KEY=base64:" .env 2>/dev/null; then\n\
    echo "Generating application key..."\n\
    php artisan key:generate --force\n\
fi\n\
\n\
# Clear all caches to ensure environment variables are read\n\
echo "Clearing caches..."\n\
php artisan config:clear\n\
php artisan cache:clear\n\
php artisan view:clear\n\
\n\
# Create SQLite database if using SQLite\n\
if [ "$DB_CONNECTION" = "sqlite" ]; then\n\
    touch /tmp/laravel.sqlite\n\
    chmod 664 /tmp/laravel.sqlite\n\
fi\n\
\n\
# Set final permissions\n\
chown -R www-data:www-data storage bootstrap/cache\n\
chmod -R 775 storage bootstrap/cache\n\
\n\
echo "Laravel application ready!"\n\
\n\
# Start Apache\n\
exec apache2-foreground\n\
' > /usr/local/bin/docker-entrypoint.sh && chmod +x /usr/local/bin/docker-entrypoint.sh

# Expose port (Render will map this)
EXPOSE 80

# Use entrypoint script
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]