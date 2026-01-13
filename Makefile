.PHONY: all up down stop start clean fclean re logs ps setup

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
	docker-compose -f $(COMPOSE_FILE) up --build -d

down:
	@echo "Stopping containers..."
	docker-compose -f $(COMPOSE_FILE) down

stop:
	@echo "Stopping containers..."
	docker-compose -f $(COMPOSE_FILE) stop

start:
	@echo "Starting containers..."
	docker-compose -f $(COMPOSE_FILE) start

clean: down
	@echo "Removing containers, networks, and volumes..."
	docker-compose -f $(COMPOSE_FILE) down -v
	@echo "Removing unused Docker resources..."
	docker system prune -af

fclean: clean
	@echo "Removing data directories..."
	@sudo rm -rf $(DATA_PATH)
	@echo "Removing all Docker images..."
	@docker rmi -f $$(docker images -qa) 2>/dev/null || true
	@docker volume rm $$(docker volume ls -q) 2>/dev/null || true

re: fclean all

logs:
	docker-compose -f $(COMPOSE_FILE) logs -f

ps:
	docker-compose -f $(COMPOSE_FILE) ps
