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

# Optimize Laravel
RUN php artisan config:clear && php artisan route:cache && php artisan view:cache

# RUN --mount=type=secret,id=_env,dst=/etc/secrets/.env cat /etc/secrets/.env

# Ensure storage/framework/sessions exists
RUN mkdir -p storage/framework/sessions \
    && chown -R www-data:www-data storage/framework/sessions \
    && chmod -R 775 storage/framework/sessions

# Expose port 80
EXPOSE 80

# Start Apache server
CMD ["apache2-foreground"]
