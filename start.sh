#!/usr/bin/env bash
set -euo pipefail

# small helper to check presence without revealing secrets
if [ -z "${OPENAI_API_KEY:-}" ]; then
  echo "ERROR: OPENAI_API_KEY is NOT set. Add it in Render Dashboard -> Environment."
else
  echo "OPENAI_API_KEY provided."
fi

# Ensure permissions
chown -R www-data:www-data storage bootstrap/cache || true

# Clear any stale caches (safe)
php artisan config:clear || true
php artisan cache:clear || true

# Ensure APP_KEY exists (recommended to set in Render env vars)
if [ -z "${APP_KEY:-}" ]; then
  echo "WARNING: APP_KEY not set. Generating a runtime key (not persistent across rebuilds)."
  php artisan key:generate --force || true
fi

# Optionally run migrations when DB configured
if [ -n "${DB_CONNECTION:-}" ] || [ -n "${DATABASE_URL:-}" ]; then
  echo "Attempting migrations..."
  php artisan migrate --force || echo "Migrations failed or are not configured — continuing."
fi

# Cache config & routes at runtime so they include Render's environment variables
php artisan config:cache || true
php artisan route:cache || true || true

# Start apache in foreground
exec apache2-foreground
