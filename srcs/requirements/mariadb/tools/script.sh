#!/bin/bash
set -e

DATADIR="/var/lib/mysql"
MYSQL_PASSWORD=$(cat /run/secrets/db_password)
MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

if [ -z "$MYSQL_DATABASE" ] || [ -z "$MYSQL_USER" ]; then
    echo "ERROR: MYSQL_DATABASE and MYSQL_USER must be set"
    exit 1
fi

echo "Database: $MYSQL_DATABASE"
echo "User: $MYSQL_USER"

if [ ! -d "$DATADIR/mysql" ]; then
    echo "Initializing MariaDB data directory..."

    mariadb-install-db --user=mysql --datadir="$DATADIR"

    mysqld --skip-networking --user=mysql &
    pid="$!"

    echo "Waiting for MariaDB to start..."
    until mysqladmin ping --silent; do
        sleep 1
    done
    echo "MariaDB started successfully"

    echo "Creating database and user..."
    mysql -u root <<-EOSQL
        CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
        CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
        GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
        ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
        FLUSH PRIVILEGES;
EOSQL

    echo "Database and user created successfully"
    
    mysqladmin shutdown -p"${MYSQL_ROOT_PASSWORD}"
    wait "$pid"
    
    echo "Initialization complete"
fi

echo "Starting MariaDB..."
exec mysqld --user=mysql
