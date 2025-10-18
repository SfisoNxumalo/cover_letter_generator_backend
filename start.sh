#!/usr/bin/env bash
set -e

# Helpful runtime checks (do not print secret values)
if [ -z "$OPENAI_API_KEY" ]; then
  echo "ERROR: OPENAI_API_KEY is NOT set. Add it in Render Dashboard -> Environment."
else
  echo "OPENAI_API_KEY is present."
fi

# Ensure permissions (sometimes needed on platforms like Render)
chown -R www-data:www-data storage bootstrap/cache || true

# Clear caches (ensure we won't use stale build-time caches)
php artisan config:clear || true
php artisan cache:clear || true

# Ensure APP_KEY: recommended to set APP_KEY in Render env vars for stability.
if [ -z "$APP_KEY" ]; then
  echo "WARNING: APP_KEY not set as an environment variable. Generating a runtime key (not persisted across image rebuilds)."
  php artisan key:generate --force
fi

# Optionally run migrations if a DB is configured (safe-guard: only attempt if DB_CONNECTION set).
if [ -n "$DB_CONNECTION" ] || [ -n "$DATABASE_URL" ]; then
  echo "Running database migrations..."
  php artisan migrate --force || echo "Migrations failed or not configured — continuing."
fi

# Cache config now that runtime env vars are available
php artisan config:cache || true
php artisan route:cache || true || true

# Finally start Apache in foreground (Render expects the container to run in foreground)
exec apache2-foreground
