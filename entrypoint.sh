#!/usr/bin/env bash
set -e

# Hard-coded DB connection info from Docker Compose environment variables
DB_HOST="${WORDPRESS_DB_HOST:-db}"
DB_USER="${WORDPRESS_DB_USER:-hdbWeejb}"
DB_PASSWORD="${WORDPRESS_DB_PASSWORD:-IdGWusgagbSzHZLfYBrb}"
DB_NAME="${WORDPRESS_DB_NAME:-wp_JWjkK}"

echo "Waiting for MySQL at $DB_HOST to start..."
sleep 10

echo "Checking if $DB_NAME is empty..."
TABLE_COUNT="$(mysql --ssl=0 -h$DB_HOST -u$DB_USER -p$DB_PASSWORD -N -B -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$DB_NAME';")"

if [ "$TABLE_COUNT" -eq 0 ]; then
  echo "No tables found in $DB_NAME. Importing usagcd-net-db-dump.sql.."
  mysql --ssl=0 -h$DB_HOST -u$DB_USER -p$DB_PASSWORD $DB_NAME  < /var/www/html/usagcd-net-db-dump.sql
else
  echo "Tables found in $DB_NAME. Skipping import."
fi

echo "Starting PHP-FPM and Nginx..."
php-fpm &
nginx -g "daemon off;"


