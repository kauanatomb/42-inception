#!/bin/bash
set -e

WP_PATH="/var/www/html"
DB_PASSWORD="$(cat /run/secrets/db_password)"
WORDPRESS_ADMIN_PASSWORD="$(cat /run/secrets/wp_admin_password)"

until mysqladmin ping -h"$WORDPRESS_DB_HOST" --silent; do
    echo "Waiting for MariaDB..."
    sleep 2
done

if [ ! -f "$WP_PATH/wp-config.php" ]; then
    echo "Installing WordPress..."
    if [ -z "$(ls -A $WP_PATH)" ]; then
        wp core download --allow-root
    else
        echo "WordPress files already present, skipping download."
    fi

    wp config create \
        --dbname="$WORDPRESS_DB_NAME" \
        --dbuser="$WORDPRESS_DB_USER" \
        --dbpass="$DB_PASSWORD" \
        --dbhost="$WORDPRESS_DB_HOST" \
        --allow-root

    wp core install \
        --url="$WORDPRESS_URL" \
        --title="$WORDPRESS_TITLE" \
        --admin_user="$WORDPRESS_ADMIN_USER" \
        --admin_password="$WORDPRESS_ADMIN_PASSWORD" \
        --admin_email="$WORDPRESS_ADMIN_EMAIL" \
        --skip-email \
        --allow-root
fi

echo "WordPress installed at $WP_PATH with DB $WORDPRESS_DB_NAME"
exec php-fpm7.4 -F
