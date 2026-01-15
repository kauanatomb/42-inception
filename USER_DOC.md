# Inception - User Documentation

This document provides clear instructions for end users and administrators on how to use and manage the Inception web infrastructure.

## Table of Contents

1. [Services Overview](#services-overview)
2. [Starting and Stopping the Project](#starting-and-stopping-the-project)
3. [Accessing the Website](#accessing-the-website)
4. [Managing Credentials](#managing-credentials)
5. [Checking Service Status](#checking-service-status)
6. [Troubleshooting](#troubleshooting)

---

## Services Overview

The Inception project provides a complete web application stack with three main services:

### 1. **NGINX Web Server**
- **Purpose**: Handles all incoming HTTPS requests and serves as a reverse proxy
- **Features**: 
  - Secure HTTPS connections (TLS 1.2/1.3)
  - SSL certificate management
  - Routes traffic to WordPress
- **Port**: 443 (HTTPS)

### 2. **WordPress**
- **Purpose**: Content Management System (CMS) for creating and managing website content
- **Features**:
  - Web interface for creating pages, posts, and media
  - User management system
  - Theme and plugin support
  - Built-in blog functionality
- **Access**: Through NGINX reverse proxy

### 3. **MariaDB Database**
- **Purpose**: Stores all WordPress data (posts, users, settings)
- **Features**:
  - Persistent data storage
  - User and permission management
  - Automated backups through volume mounting
- **Access**: Internal only (not exposed to external network)

---

## Starting and Stopping the Project

### Starting the Project

To start all services, run:

```bash
make
```

**What this does**:
- Creates data directories if they don't exist
- Builds Docker images for all services
- Starts all containers in the background

**First-time setup**: The initial startup may take 2-5 minutes as Docker downloads base images and builds the containers.

### Alternative Start Commands

```bash
# Start without rebuilding
make start

# Build and start (if images already exist)
make up
```

### Stopping the Project

To stop all running services:

```bash
make down
```

This stops and removes the containers but **preserves your data** (database and WordPress files).

### Temporary Stop (Without Removal)

To temporarily stop services without removing containers:

```bash
make stop
```

To restart them later:

```bash
make start
```

---

## Accessing the Website

### Website Access

Once the services are running, access the website through your web browser:

**URL**: https://ktombola.42.fr (or your configured domain name)

**Important**: 
- The site uses HTTPS only (HTTP is not available)
- You may see a security warning because it uses a self-signed certificate
- Click "Advanced" → "Accept Risk and Continue" (Firefox) or "Proceed to site" (Chrome)

### WordPress Administration Panel

To access the WordPress admin dashboard:

**URL**: https://ktombola.42.fr/wp-admin

**Login Credentials**:
- **Username**: Configured in `.env` file (`WORDPRESS_ADMIN_USER`)
- **Password**: Stored in `secrets/wp_admin_password.txt`

### First-Time WordPress Setup

When accessing WordPress for the first time:
1. Open https://ktombola.42.fr in your browser
2. The site should already be installed and configured
3. Navigate to `/wp-admin` to log in
4. Use the admin credentials (see [Managing Credentials](#managing-credentials))

---

## Managing Credentials

### Credential Location

All sensitive credentials are stored in two locations:

#### 1. **Docker Secrets** (Passwords)
Located in the `secrets/` directory:

```
secrets/
├── db_password.txt          # Database user password
├── db_root_password.txt     # Database root password
├── wp_admin_password.txt    # WordPress admin password
└── wp_user_password.txt     # WordPress second user password
```

**To view a password**:
```bash
cat secrets/wp_admin_password.txt
```

#### 2. **Environment Variables** (Usernames, Emails, URLs)
Located in `srcs/.env` file:

**To view all configuration**:
```bash
cat srcs/.env
```

**Key variables**:
- `WORDPRESS_ADMIN_USER` - Admin username
- `WORDPRESS_ADMIN_EMAIL` - Admin email
- `WORDPRESS_USER` - Second user username
- `WORDPRESS_URL` - Website URL

### Changing Passwords

**Important**: Do not change passwords while containers are running.

**Steps to change a password**:

1. Stop the services:
   ```bash
   make down
   ```

2. Edit the appropriate secret file:
   ```bash
   echo "new_secure_password" > secrets/wp_admin_password.txt
   ```

3. Clean and rebuild:
   ```bash
   make fclean
   make
   ```

**Warning**: Changing database passwords requires rebuilding the entire stack and will reset the database.

### Changing Configuration

To change non-sensitive settings (usernames, emails, domain):

1. Stop the services:
   ```bash
   make down
   ```

2. Edit the `.env` file:
   ```bash
   vim srcs/.env
   ```

3. Restart:
   ```bash
   make up
   ```

---

## Checking Service Status

### Quick Status Check

View all running containers:

```bash
make ps
```

**Expected output** (when running correctly):
```
NAME        IMAGE        STATUS        PORTS
nginx       nginx        Up X minutes  0.0.0.0:443->443/tcp
wordpress   wordpress    Up X minutes  
mariadb     mariadb      Up X minutes  
```

All three services should show "Up" status.

### Viewing Service Logs

To view logs from all services:

```bash
make logs
```

**To view logs from a specific service**:

```bash
docker compose -f srcs/docker-compose.yml logs nginx
docker compose -f srcs/docker-compose.yml logs wordpress
docker compose -f srcs/docker-compose.yml logs mariadb
```

**To follow logs in real-time**:

```bash
docker compose -f srcs/docker-compose.yml logs -f
```

Press `Ctrl+C` to stop following logs.

### Testing Website Connectivity

**Method 1: Web Browser**
- Open https://ktombola.42.fr
- You should see the WordPress homepage

**Method 2: Command Line**
```bash
curl -k https://ktombola.42.fr
```

If working correctly, you'll see HTML output from WordPress.

### Checking Individual Services

**NGINX** (Web Server):
```bash
docker exec nginx nginx -t
```
Should show "test is successful"

**WordPress** (PHP-FPM):
```bash
docker exec wordpress ps aux | grep php-fpm
```
Should show multiple php-fpm processes running

**MariaDB** (Database):
```bash
docker exec mariadb pgrep -f mysqld
```
Should show one process ID if MariaDB is running

**Alternative - Check with authentication**:
```bash
docker exec mariadb mysqladmin ping -u root -p$(cat secrets/db_root_password.txt)
```
Should show "mysqld is alive"

### Checking Data Persistence

Verify that your data directories exist and contain files:

```bash
ls -lh /home/ktombola/data/mariadb/
ls -lh /home/ktombola/data/wordpress/
```

**Expected**:
- MariaDB directory: Should contain database files (mysql/, wordpress/)
- WordPress directory: Should contain WordPress files (wp-content/, wp-config.php)

---

## Troubleshooting

### Problem: Cannot Access Website

**Symptoms**: Browser shows "This site can't be reached" or connection timeout

**Solutions**:

1. **Check if containers are running**:
   ```bash
   make ps
   ```
   All three services should be "Up"

2. **Check /etc/hosts configuration**:
   ```bash
   cat /etc/hosts | grep ktombola
   ```
   Should contain: `127.0.0.1 ktombola.42.fr`
   
   If missing, add it:
   ```bash
   echo "127.0.0.1 ktombola.42.fr" | sudo tee -a /etc/hosts
   ```

### Problem: Container Keeps Restarting

**Symptoms**: Container status shows "Restarting" or keeps going up and down

**Solutions**:

1. **Check container logs**:
   ```bash
   make logs
   ```
   Look for error messages

2. **Check if secrets exist**:
   ```bash
   ls -la secrets/
   ```
   All four password files must exist

3. **Check if .env file exists**:
   ```bash
   cat srcs/.env
   ```

4. **Rebuild from scratch**:
   ```bash
   make fclean
   make
   ```

### Problem: WordPress Shows Database Connection Error

**Symptoms**: White page with "Error establishing a database connection"

**Solutions**:

1. **Wait for MariaDB to fully start** (may take 30-60 seconds on first run)

2. **Verify database credentials match**:
   - Check `srcs/.env`: WORDPRESS_DB_USER and MYSQL_USER must be identical
   - Check `srcs/.env`: WORDPRESS_DB_NAME and MYSQL_DATABASE must be identical

3. **Check MariaDB logs**:
   ```bash
   docker compose -f srcs/docker-compose.yml logs mariadb
   ```

### Problem: SSL Certificate Warning

**Symptoms**: Browser shows "Your connection is not private" or security warning

**This is normal**: The project uses self-signed certificates for HTTPS.

**To proceed**:
- **Firefox**: Click "Advanced" → "Accept the Risk and Continue"
- **Chrome**: Click "Advanced" → "Proceed to ktombola.42.fr (unsafe)"
- **Safari**: Click "Show Details" → "visit this website"

### Problem: Permission Denied Errors

**Symptoms**: Errors about unable to create files or directories

**Solutions**:

1. **Check data directory permissions**:
   ```bash
   ls -ld /home/ktombola/data/
   ```

2. **Fix permissions if needed**:
   ```bash
   sudo chown -R $USER:$USER /home/ktombola/data/
   sudo chmod -R 755 /home/ktombola/data/
   ```

3. **Rebuild**:
   ```bash
   make fclean
   make
   ```

### Getting Help

If problems persist:

1. **Check all logs**:
   ```bash
   make logs > logs.txt
   ```

2. **Check Docker status**:
   ```bash
   docker ps -a
   docker volume ls
   docker network ls
   ```

3. **Verify configuration files**:
   - Check `srcs/.env` for typos
   - Verify all secrets files exist
   - Check Makefile paths match your system

4. **Try a complete reset**:
   ```bash
   make fclean
   make
   ```
   **Warning**: This deletes all data including database and uploaded files!

---

## Quick Reference

### Main essential Commands

| Command | Description |
|---------|-------------|
| `make` | Build and start everything |
| `make down` | Stop and remove containers |
| `make logs` | View all service logs |
| `make ps` | Check container status |
| `make clean` | Stop and remove volumes |
| `make fclean` | Complete cleanup (removes data!) |

### Important URLs

| Service | URL |
|---------|-----|
| WordPress Site | https://ktombola.42.fr |
| Admin Dashboard | https://ktombola.42.fr/wp-admin |
| WordPress Login | https://ktombola.42.fr/wp-login.php |

### Important Files

| File | Purpose |
|------|---------|
| `secrets/wp_admin_password.txt` | Admin password |
| `secrets/wp_user_password.txt` | User password |
| `srcs/.env` | Configuration (usernames, emails) |
| `/home/ktombola/data/` | Persistent data storage |

---

## Security Reminders

✅ **Do**: Keep password files secure and private  
✅ **Do**: Use strong passwords in production  
✅ **Do**: Regularly backup `/home/ktombola/data/` directory  
✅ **Do**: Keep Docker and system packages updated  

❌ **Don't**: Commit `.env` or `secrets/` files to Git  
❌ **Don't**: Share password files publicly  
❌ **Don't**: Use default or weak passwords  
❌ **Don't**: Expose the database port to external network  

---

*For technical details and architecture information, see [README.md](README.md)*
