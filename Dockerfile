# Dockerfile for Render (Docker runtime)
FROM php:8.3-apache

# set working dir
WORKDIR /var/www/html

# Install system packages + PHP extensions
RUN apt-get update \
  && apt-get install -y git unzip libpng-dev libonig-dev libxml2-dev zip curl sqlite3 \
  && docker-php-ext-install pdo pdo_mysql mbstring exif pcntl bcmath gd \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Enable apache rewrite and set DocumentRoot to Laravel public
RUN a2enmod rewrite
RUN sed -i 's|/var/www/html|/var/www/html/public|g' /etc/apache2/sites-available/000-default.conf

# Allow .htaccess overrides
RUN printf '%s\n' '<Directory /var/www/html/public>' \
    '    Options Indexes FollowSymLinks' \
    '    AllowOverride All' \
    '    Require all granted' \
    '</Directory>' > /etc/apache2/conf-available/laravel.conf \
    && a2enconf laravel

# Copy composer binary from composer image
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# ========== Composer install step (no scripts yet) ==========
# Copy only composer manifests to leverage layer caching
COPY composer.json composer.lock /var/www/html/

# Install PHP dependencies but skip scripts that call artisan (artisan not copied yet)
RUN composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist --no-scripts

# ========== Copy application code after vendor installed ==========
# Important: .dockerignore should exclude .env and vendor to avoid leaking secrets and extra copy
COPY . /var/www/html

# Now that artisan and app files exist, run post-install tasks safely
# Generate optimized autoload files and run package discovery
RUN composer dump-autoload --optimize --no-interaction \
  && php artisan package:discover --ansi || true

# Permissions
RUN chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache \
    && mkdir -p storage/framework/sessions \
    && chown -R www-data:www-data storage/framework/sessions \
    && chmod -R 775 storage/framework/sessions

# Copy runtime start script and make executable
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 80

# Start script will run artisan commands that depend on runtime envs (Render envs)
CMD ["/start.sh"]
