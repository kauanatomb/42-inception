.PHONY: all up down stop start clean fclean re logs ps setup

COMPOSE = docker compose
COMPOSE_FILE = srcs/docker-compose.yml
DATA_PATH = /home/ktombola/data
MARIADB_DATA = $(DATA_PATH)/mariadb
WORDPRESS_DATA = $(DATA_PATH)/wordpress

all: setup up

setup:
	@if [ ! -d "$(MARIADB_DATA)" ] || [ ! -d "$(WORDPRESS_DATA)" ]; then \
		echo "Creating data directories..."; \
		mkdir -p $(MARIADB_DATA); \
		mkdir -p $(WORDPRESS_DATA); \
	fi

up:
	@echo "Building and starting containers..."
	$(COMPOSE) -f $(COMPOSE_FILE) up --build -d

down:
	@echo "Stopping containers..."
	$(COMPOSE) -f $(COMPOSE_FILE) down

stop:
	@echo "Stopping containers..."
	$(COMPOSE) -f $(COMPOSE_FILE) stop

start:
	@echo "Starting containers..."
	$(COMPOSE) -f $(COMPOSE_FILE) start

clean: down
	@echo "Removing containers, networks, and volumes..."
	$(COMPOSE) -f $(COMPOSE_FILE) down -v

fclean: clean
	@echo "Removing data directories..."
	@sudo rm -rf $(MARIADB_DATA) $(WORDPRESS_DATA)

re: fclean all

logs:
	$(COMPOSE) -f $(COMPOSE_FILE) logs 

ps:
	$(COMPOSE) -f $(COMPOSE_FILE) ps
