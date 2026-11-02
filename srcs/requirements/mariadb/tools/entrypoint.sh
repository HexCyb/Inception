#!/bin/sh
# First start: create the system tables, the WordPress database and its user,
# and set the root password. Every start: hand PID 1 over to mariadbd.
set -eu

DB_PASSWORD="$(cat /run/secrets/db_password)"
DB_ROOT_PASSWORD="$(cat /run/secrets/db_root_password)"

chown -R mysql:mysql /var/lib/mysql /run/mysqld

if [ ! -d "/var/lib/mysql/${MYSQL_DATABASE}" ]; then
    echo "[mariadb] first start: creating database '${MYSQL_DATABASE}'"
    if [ ! -d /var/lib/mysql/mysql ]; then
        mariadb-install-db --user=mysql --datadir=/var/lib/mysql --skip-test-db > /dev/null
    fi
    # bootstrap mode runs the SQL without opening any network port
    mariadbd --user=mysql --bootstrap <<EOF
FLUSH PRIVILEGES;
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
DELETE FROM mysql.user WHERE User = '';
FLUSH PRIVILEGES;
EOF
    echo "[mariadb] database ready"
fi

exec "$@"
