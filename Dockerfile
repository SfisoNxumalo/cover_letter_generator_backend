# Use official PHP image with Apache
FROM php:8.3-apache

# Set working directory
WORKDIR /var/www/html

# Install system dependencies and PHP extensions
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    curl \
    && docker-php-ext-install pdo pdo_mysql mbstring exif pcntl bcmath gd \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Configure Apache DocumentRoot
RUN sed -i 's|/var/www/html|/var/www/html/public|g' /etc/apache2/sites-available/000-default.conf \
    && echo '<Directory /var/www/html/public>\n\
    Options Indexes FollowSymLinks\n\
    AllowOverride All\n\
    Require all granted\n\
</Directory>' > /etc/apache2/conf-available/laravel.conf \
    && a2enconf laravel

# Copy Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Copy application files
COPY . .

# Install Composer dependencies
RUN composer install --no-interaction --no-dev --optimize-autoloader

# Create necessary directories
RUN mkdir -p storage/logs storage/framework/sessions storage/framework/views storage/framework/cache bootstrap/cache

# Set permissions
RUN chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# Don't create .env yet - do it at runtime

# Expose port
EXPOSE 80

# Startup command
CMD bash -c '\
    cp .env.example .env && \
    php artisan key:generate --force && \
    touch /tmp/laravel.sqlite && \
    chmod 666 /tmp/laravel.sqlite && \
    sed -i "s|DB_CONNECTION=.*|DB_CONNECTION=sqlite|" .env && \
    sed -i "s|DB_DATABASE=.*|DB_DATABASE=/tmp/laravel.sqlite|" .env && \
    sed -i "s|SESSION_DRIVER=.*|SESSION_DRIVER=file|" .env && \
    sed -i "s|CACHE_DRIVER=.*|CACHE_DRIVER=file|" .env && \
    echo "" >> .env && \
    echo "OPENAI_API_KEY=${OPENAI_API_KEY}" >> .env && \
    chown -R www-data:www-data storage bootstrap/cache && \
    apache2-foreground'