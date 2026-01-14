# Inception

*This project has been created as part of the 42 curriculum by ktombola.*

## Description

Inception is a system administration and Docker orchestration project that focuses on containerization and infrastructure management. The goal is to set up a multi-container application using Docker Compose, implementing a complete web infrastructure with NGINX, WordPress, and MariaDB, while following security best practices and modern DevOps principles.

The project focus on understanding containerization concepts, networking, volume management, and secure credential handling through Docker secrets. All services run in separate containers, communicate through a custom Docker network, and use TLS encryption for secure connections.

## Instructions

### Prerequisites

- Project must run in a virtual machine
- Docker and Docker Compose installed
- Root or sudo privileges (required for creating data directories)
- `/etc/hosts` file configured with your domain name (e.g., `127.0.0.1 ktombola.42.fr`)

### Configuration

#### 1. Environment Variables (`.env` file)

Create or update the `srcs/.env` file with the following variables:

```bash
# ===== MariaDB Configuration =====
MYSQL_DATABASE=X        # Database name
MYSQL_USER=X            # Database user (non-root)

# ===== WordPress Database Connection =====
WORDPRESS_DB_NAME=X     # Must match MYSQL_DATABASE
WORDPRESS_DB_USER=X     # Must match MYSQL_USER
WORDPRESS_DB_HOST=X     # Service name (from docker-compose.yml)

# ===== WordPress Site Configuration =====
WORDPRESS_URL=X         # Site URL (HTTPS required)
WORDPRESS_TITLE=X       # Website title
WORDPRESS_ADMIN_USER=X  # WordPress admin username
WORDPRESS_ADMIN_EMAIL=X # Admin email

# ===== WordPress Additional User =====
WORDPRESS_USER=X        # Second WordPress user
WORDPRESS_USER_EMAIL=X  # User email

# ===== NGINX Configuration =====
DOMAIN_NAME=X           # Domain name for NGINX SSL certificate and server name
```

**Important**: Replace all values with your own login and preferences.

#### 2. Docker Secrets (Sensitive Credentials)

Create the following secret files in the `secrets/` directory with actual passwords:

- `secrets/db_password.txt` - Database user password (referenced as `MYSQL_PASSWORD` in scripts)
- `secrets/db_root_password.txt` - Database root password (only for root MariaDB access)
- `secrets/wp_admin_password.txt` - WordPress admin user password
- `secrets/wp_user_password.txt` - WordPress second user password

**Important**: These files contain sensitive credentials and environment variables must be added to `.gitignore`.

#### 3. Update Data Paths

Modify the `DATA_PATH` variable in the Makefile if needed (default: `/home/ktombola/data`):
```makefile
DATA_PATH = /home/ktombola/data
```

This path must exist and be writable by your user, as it stores persistent MariaDB and WordPress data.

### Compilation and Installation

Build and start all services:
```bash
make
```

This command will:
- Create necessary data directories for persistent storage
- Build Docker images for all services
- Start containers in detached mode

### Available Commands

```bash
make           # Create data directories if needed and build/start all containers (default)
make setup     # Create persistent storage directories if they don't exist
make up        # Build and start containers
make down      # Stop and remove containers
make stop      # Stop containers without removing them
make start     # Start previously stopped containers
make clean     # Stop containers and remove volumes
make fclean    # Remove everything including data directories
make re        # Full rebuild (fclean + all)
make logs      # View container logs
make ps        # List running containers
```

### Accessing the Application

Once the containers are running, access the WordPress site via:
- **HTTPS**: https://ktombola.42.fr (or your configured domain)
- **Port**: 443 (HTTPS only, no HTTP access)

## Project Description

### Overview

This project implements a complete web application stack using Docker containers. The infrastructure consists of three main services:

1. **NGINX** - Web server and reverse proxy with TLS/SSL encryption
2. **WordPress** - Content management system with PHP-FPM
3. **MariaDB** - Relational database management system

All services are orchestrated using Docker Compose and communicate through a custom bridge network.

### Docker Architecture

The project leverages Docker's containerization technology to create isolated, portable, and reproducible environments. Each service runs in its own container with specific configurations, dependencies, and resource allocations.

#### Key Components:

- **Dockerfiles**: Custom images built from Bookworm base images
- **Docker Compose**: Orchestration tool managing multi-container dependencies
- **Docker Networks**: Isolated network for inter-container communication
- **Docker Volumes**: Persistent storage for database and WordPress files
- **Docker Secrets**: Secure credential management

### Design Choices

#### 1. Base Image Selection
- **Debian Bookworm**: Chosen for stability, security updates, and extensive package availability
- **Penultimate version**: Balances stability with modern features
- **No Alpine**: While smaller, Debian provides better compatibility and documentation

#### 2. Environment Variables vs Docker Secrets Strategy
- **Environment Variables (`.env`)**: Used for non-sensitive configuration data (database names, usernames, URLs, emails, domain names)
- **Docker Secrets (`secrets/` directory)**: Used exclusively for sensitive credentials (passwords, keys)
- This separation follows the principle of least privilege and prevents accidental exposure of passwords in logs or environment variable listings

#### 3. Service Architecture
- **NGINX as reverse proxy**: Handles TLS termination and forwards PHP requests to WordPress
- **PHP-FPM**: Separate process manager for better performance and resource management
- **Separate database container**: Isolation improves security and scalability

#### 4. Security Measures
- **TLS 1.2/1.3 only**: Modern encryption protocols
- **Docker secrets**: Sensitive credentials stored securely
- **No default passwords**: All credentials externalized
- **Network isolation**: Services communicate only through defined networks

### Technical Comparisons

#### Virtual Machines vs Docker

| Aspect | Virtual Machines | Docker Containers |
|--------|-----------------|-------------------|
| **Isolation** | Complete OS-level isolation with hypervisor | Process-level isolation using kernel features |
| **Resource Usage** | High - each VM runs full OS (GBs of RAM) | Low - shares host kernel (MBs of RAM) |
| **Startup Time** | Minutes (full OS boot) | Seconds (process start) |
| **Portability** | Limited - large VM images | High - lightweight, layered images |
| **Performance** | Overhead from hypervisor | Near-native performance |
| **Use Case** | Full isolation, different OS requirements | Microservices, rapid deployment, dev/prod parity |

**Choice**: Docker is ideal for this project due to faster deployment, lower resource consumption, and better scalability for web applications.

#### Secrets vs Environment Variables

| Aspect | Docker Secrets | Environment Variables |
|--------|---------------|----------------------|
| **Security** | Encrypted at rest and in transit | Visible in process lists and logs |
| **Storage** | Mounted as in-memory files (/run/secrets) | Stored in container configuration |
| **Visibility** | Only accessible by designated services | Can be viewed with `docker inspect` |
| **Rotation** | Can be updated without rebuilding | Requires container restart |
| **Best For** | Passwords, API keys, certificates | Non-sensitive configuration |

**Choice**: Docker secrets are used for all sensitive credentials (passwords, keys) to prevent accidental exposure in logs or environment variable listings.

#### Docker Network vs Host Network

| Aspect | Bridge Network (Docker Network) | Host Network |
|--------|-------------------------------|--------------|
| **Isolation** | Complete network isolation | Direct host network access |
| **Port Mapping** | Explicit port publishing required | All ports directly exposed |
| **Security** | Services only accessible via published ports | All services exposed to host network |
| **DNS** | Built-in service discovery by name | Manual IP/hostname management |
| **Performance** | Slight overhead from network bridge | Native network performance |
| **Use Case** | Microservices, controlled exposure | High-performance networking needs |

**Choice**: Custom bridge network (`inception_net`) provides service isolation, built-in DNS resolution (services can reach each other by name), and controlled port exposure (only NGINX port 443 is published).

#### Docker Volumes vs Bind Mounts

| Aspect | Named Volumes | Bind Mounts |
|--------|--------------|-------------|
| **Management** | Docker manages storage location | User specifies exact host path |
| **Portability** | Platform-independent | Path must exist on host |
| **Permissions** | Docker handles permissions | May require host permission setup |
| **Backup** | `docker volume` commands | Standard filesystem tools |
| **Performance** | Optimized by Docker | Direct filesystem access |
| **Use Case** | Production data, Docker-managed | Development, host file sharing |

**Choice**: This project uses **bind mounts configured as named volumes**:
- Explicit control over data location (`/home/ktombola/data`)
- Easy backup and inspection of database and WordPress files
- Persistence across container recreation
- Data survives `docker-compose down` (but not `make fclean`)

### Configuration Files Structure

#### Version Control

**Committed to Git** (tracked):
```
inception/
├── Makefile                          # Automation commands
├── README.md                         # Project documentation
└── srcs/
    ├── docker-compose.yml            # Service orchestration
    └── requirements/                 # Dockerfile and configuration
```

**NOT Committed to Git** (add to `.gitignore`):
```
secrets/                             # Sensitive credentials - CREATE MANUALLY
├── db_password.txt                   # Database user password
├── db_root_password.txt              # Database root password
├── wp_admin_password.txt             # WordPress admin password
└── wp_user_password.txt              # WordPress second user password

srcs/.env                            # Environment variables - CREATE MANUALLY
```

#### Full Source Files Structure

```
inception/
├── Makefile                          # Automation commands
├── secrets/                          # Sensitive credentials (gitignored)
│   ├── db_password.txt
│   ├── db_root_password.txt
│   ├── wp_admin_password.txt
│   └── wp_user_password.txt
└── srcs/
    ├── docker-compose.yml            # Service orchestration
    ├── .env                          # Environment variables (gitignored)
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile            # MariaDB image build
        │   ├── conf/
        │   │   └── 50-server.cnf     # Database configuration
        │   └── tools/
        │       └── script.sh         # Database initialization script
        ├── nginx/
        │   ├── Dockerfile            # NGINX image build
        │   └── conf/
        │       └── default.conf      # NGINX server configuration
        └── wordpress/
            ├── Dockerfile            # WordPress image build
            └── tools/
                └── script.sh         # WordPress installation script
```

## Resources

### Documentation and Tutorials

- **NGINX TLS Configuration**: [Configure NGINX to use only TLS 1.2 and 1.3](https://www.cyberciti.biz/faq/configure-nginx-to-use-only-tls-1-2-and-1-3/) - Security best practices for NGINX SSL/TLS setup
- **Debian Releases**: [Official Debian Release Information](https://www.debian.org/releases/index.fr.html) - Understanding Debian version lifecycle
- **Docker Documentation**: [docs.docker.com](https://docs.docker.com/manuals) - Official Docker documentation for Dockerfile syntax, Docker Compose, volume management, bind mounts, and networking concepts
- **Wikipedia**: Articles on proxy servers, containerization, NGINX, and related web technologies

### AI Usage in This Project

Throughout the development of this project, AI assistance was used for:

1. **Exploration and Learning**:
   - Understanding different approaches to the same problem (e.g., volume configurations)
   - Comparing implementation strategies (secrets vs environment variables)
   - Learning Docker Compose syntax and best practices

2. **Code Review and Optimization**:
   - Suggesting improvements to Dockerfile instructions and README file
   - Optimizing shell scripts for container initialization

3. **Problem-Solving Approaches**:
   - Providing multiple solutions to implement the same functionality
   - Suggesting alternative methods according to user input

## Author

**ktombola** - 42 Student

