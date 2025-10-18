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

# Disable database requirement by using file-based sessions
RUN sed -i "s/DB_CONNECTION=.*/DB_CONNECTION=sqlite/" .env \
    && sed -i "s/DB_DATABASE=.*/DB_DATABASE=\/tmp\/laravel.sqlite/" .env \
    && sed -i "s/SESSION_DRIVER=.*/SESSION_DRIVER=file/" .env \
    && sed -i "s/CACHE_DRIVER=.*/CACHE_DRIVER=file/" .env \
    && sed -i "s/QUEUE_CONNECTION=.*/QUEUE_CONNECTION=sync/" .env

# Generate app key
RUN php artisan key:generate

# Ensure storage/framework/sessions exists
RUN mkdir -p storage/framework/sessions \
    && chown -R www-data:www-data storage/framework/sessions \
    && chmod -R 775 storage/framework/sessions

# Create startup script that injects runtime environment variables
RUN echo '#!/bin/bash\n\
\n\
# Inject Render environment variables into .env file\n\
if [ ! -z "$OPENAI_API_KEY" ]; then\n\
    # Remove existing OPENAI_API_KEY if present\n\
    sed -i "/^OPENAI_API_KEY=/d" .env\n\
    # Add the new one from Render\n\
    echo "OPENAI_API_KEY=${OPENAI_API_KEY}" >> .env\n\
    echo "✓ OpenAI API Key injected from environment"\n\
fi\n\
\n\
if [ ! -z "$OPENAI_ORGANIZATION" ]; then\n\
    sed -i "/^OPENAI_ORGANIZATION=/d" .env\n\
    echo "OPENAI_ORGANIZATION=${OPENAI_ORGANIZATION}" >> .env\n\
fi\n\
\n\
# Update APP_URL if provided\n\
if [ ! -z "$APP_URL" ]; then\n\
    sed -i "s|^APP_URL=.*|APP_URL=${APP_URL}|" .env\n\
fi\n\
\n\
# Create SQLite database\n\
touch /tmp/laravel.sqlite\n\
chmod 666 /tmp/laravel.sqlite\n\
\n\
# Clear config cache to ensure new env vars are loaded\n\
php artisan config:clear\n\
\n\
# Set permissions\n\
chown -R www-data:www-data storage bootstrap/cache\n\
chmod -R 775 storage bootstrap/cache\n\
\n\
# Start Apache\n\
exec apache2-foreground\n\
' > /usr/local/bin/start.sh && chmod +x /usr/local/bin/start.sh

# Expose port 80
EXPOSE 80

# Start Apache server using our startup script
CMD ["/usr/local/bin/start.sh"]yy