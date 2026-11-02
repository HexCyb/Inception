#!/bin/sh
# First start: download WordPress, write wp-config.php, install the site and
# create its two users. Every start: hand PID 1 over to php-fpm.
set -eu

DB_PASSWORD="$(cat /run/secrets/db_password)"
WP_ADMIN_PASSWORD="$(cat /run/secrets/wp_admin_password)"
WP_USER_PASSWORD="$(cat /run/secrets/wp_user_password)"

case "$(printf '%s' "$WP_ADMIN_USER" | tr '[:upper:]' '[:lower:]')" in
    *admin*) echo "[wordpress] WP_ADMIN_USER must not contain 'admin'" >&2; exit 1 ;;
esac

# MariaDB is healthy before this container starts; this only covers a slow first boot
tries=0
until mariadb -h mariadb -u "$MYSQL_USER" -p"$DB_PASSWORD" -e 'SELECT 1' "$MYSQL_DATABASE" > /dev/null 2>&1; do
    tries=$((tries + 1))
    if [ "$tries" -ge 30 ]; then
        echo "[wordpress] cannot reach MariaDB" >&2
        exit 1
    fi
    sleep 2
done

if [ ! -f wp-config.php ]; then
    echo "[wordpress] first start: installing WordPress"
    wp core download --allow-root
    wp config create --allow-root \
        --dbname="$MYSQL_DATABASE" --dbuser="$MYSQL_USER" --dbpass="$DB_PASSWORD" --dbhost=mariadb:3306
    wp core install --allow-root \
        --url="https://${DOMAIN_NAME}" --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" --skip-email
    wp user create --allow-root "$WP_USER" "$WP_USER_EMAIL" --role=author --user_pass="$WP_USER_PASSWORD"
    chown -R www-data:www-data /var/www/html
    echo "[wordpress] ready at https://${DOMAIN_NAME}"
fi

exec "$@"
