#!/bin/bash
set -e

DATADIR="/var/lib/mysql"
MYSQL_PASSWORD=$(cat /run/secrets/db_password)
MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)


if [ ! -d "$DATADIR/mysql" ]; then
    echo "Initializing MariaDB data directory..."

    mariadb-install-db --user=mysql --datadir="$DATADIR"

    mysqld --skip-networking &
    pid="$!"

    until mysqladmin ping --silent; do
        sleep 1
    done

    mysql -u root <<-EOSQL
        CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
        CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
        GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
        ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
        FLUSH PRIVILEGES;
EOSQL

    mysqladmin shutdown
    wait "$pid"
fi

exec mysqld --user=mysql
