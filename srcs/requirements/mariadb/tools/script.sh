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
    NEEDS_INIT=1
elif [ ! -d "$DATADIR/$MYSQL_DATABASE" ]; then
    echo "Database directory does not exist, initialization needed..."
    NEEDS_INIT=1
else
    NEEDS_INIT=0
fi

if [ "$NEEDS_INIT" = "1" ]; then
    echo "Starting temporary MariaDB for initialization..."
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
    
    if ! mysqladmin shutdown -p"${MYSQL_ROOT_PASSWORD}" 2>/dev/null; then
        mysqladmin shutdown
    fi
    wait "$pid"
    
    echo "Initialization complete"
fi

echo "Starting MariaDB..."
exec mysqld --user=mysql
