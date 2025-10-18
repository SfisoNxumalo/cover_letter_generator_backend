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

# Configure Apache to show PHP errors in logs
RUN echo 'php_flag display_errors on\n\
php_flag display_startup_errors on\n\
php_value error_reporting E_ALL' >> /etc/apache2/apache2.conf

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
echo "=== Starting Laravel application on Render ==="\n\
\n\
# Create .env file\n\
cat > .env << "ENVEOF"\n\
APP_NAME=Laravel\n\
APP_ENV=production\n\
APP_DEBUG=true\n\
APP_URL=http://localhost\n\
\n\
LOG_CHANNEL=stack\n\
LOG_DEPRECATIONS_CHANNEL=null\n\
LOG_LEVEL=debug\n\
\n\
DB_CONNECTION=sqlite\n\
DB_DATABASE=/tmp/database.sqlite\n\
\n\
BROADCAST_DRIVER=log\n\
CACHE_DRIVER=file\n\
FILESYSTEM_DISK=local\n\
QUEUE_CONNECTION=sync\n\
SESSION_DRIVER=file\n\
SESSION_LIFETIME=120\n\
ENVEOF\n\
\n\
# Append environment variables from Render\n\
echo "" >> .env\n\
echo "# Runtime environment variables" >> .env\n\
[ ! -z "$APP_KEY" ] && echo "APP_KEY=$APP_KEY" >> .env\n\
[ ! -z "$OPENAI_API_KEY" ] && echo "OPENAI_API_KEY=$OPENAI_API_KEY" >> .env\n\
[ ! -z "$OPENAI_ORGANIZATION" ] && echo "OPENAI_ORGANIZATION=$OPENAI_ORGANIZATION" >> .env\n\
\n\
echo "=== Environment file created ==="\n\
\n\
# Generate APP_KEY if not exists\n\
if ! grep -q "^APP_KEY=base64:" .env; then\n\
    echo "Generating APP_KEY..."\n\
    php artisan key:generate --force\n\
fi\n\
\n\
# Create SQLite database\n\
touch /tmp/database.sqlite\n\
chmod 666 /tmp/database.sqlite\n\
\n\
# Verify OpenAI key is set\n\
if grep -q "^OPENAI_API_KEY=" .env; then\n\
    echo "✓ OpenAI API Key is configured"\n\
else\n\
    echo "⚠ WARNING: OPENAI_API_KEY not found in environment!"\n\
fi\n\
\n\
# Set permissions\n\
chown -R www-data:www-data storage bootstrap/cache /tmp/database.sqlite\n\
chmod -R 775 storage bootstrap/cache\n\
\n\
echo "=== Laravel application ready ==="\n\
echo "=== Logs will appear below ==="\n\
\n\
# Tail logs in background\n\
tail -f storage/logs/*.log 2>/dev/null &\n\
\n\
# Start Apache in foreground\n\
exec apache2-foreground\n\
' > /usr/local/bin/docker-entrypoint.sh && chmod +x /usr/local/bin/docker-entrypoint.sh

# Expose port
EXPOSE 80

# Use entrypoint script
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]