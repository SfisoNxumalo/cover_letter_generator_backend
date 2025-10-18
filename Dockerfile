# Dockerfile (for Render Docker runtime)
FROM php:8.3-apache

WORKDIR /var/www/html

# system deps + php extensions
RUN apt-get update && apt-get install -y \
    git unzip libpng-dev libonig-dev libxml2-dev zip curl sqlite3 \
    && docker-php-ext-install pdo pdo_mysql mbstring exif pcntl bcmath gd \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# enable apache mod_rewrite and set document root
RUN a2enmod rewrite
RUN sed -i 's|/var/www/html|/var/www/html/public|g' /etc/apache2/sites-available/000-default.conf

# Allow .htaccess overrides for Laravel
RUN printf '%s\n' '<Directory /var/www/html/public>' \
    '    Options Indexes FollowSymLinks' \
    '    AllowOverride All' \
    '    Require all granted' \
    '</Directory>' > /etc/apache2/conf-available/laravel.conf \
    && a2enconf laravel

# copy composer binary
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Install PHP deps based on composer files (faster build)
COPY composer.json composer.lock /var/www/html/
RUN composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist

# Copy application code (do NOT copy local .env; .dockerignore will exclude it)
COPY . /var/www/html

# permissions
RUN chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache \
    && mkdir -p storage/framework/sessions \
    && chown -R www-data:www-data storage/framework/sessions \
    && chmod -R 775 storage/framework/sessions

# Copy the runtime start script
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 80

# Start script will prepare config with runtime envs, then start apache
CMD ["/start.sh"]
