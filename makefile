# Makefile for local dev workflow

# Load environment variables from .env file
ifneq (,$(wildcard ./.env))
	include .env
	export
endif

# Variables
# ------------------------------------------------------------------------------
DOCKER_COMPOSE = docker compose -f docker-compose-local.yml
DB_SERVICE = db
DB_DUMP_FILE = usagcd-net-db-dump.sql

# 1. Setup: builds and starts containers in the background, waits for MySQL to be ready, and restores the database
setup:
	$(DOCKER_COMPOSE) up --build -d
	@echo "Waiting for MySQL to be ready..."
	@while ! $(DOCKER_COMPOSE) exec $(DB_SERVICE) mysql -u$(DB_USER) -p$(DB_PASSWORD) -e "SHOW DATABASES;" 2>/dev/null; do \
		echo "MySQL not ready. Retrying..."; \
		sleep 2; \
	done
	@echo "MySQL is ready. Checking and restoring the database..."
	@if [ -f $(DB_DUMP_FILE) ]; then \
		$(DOCKER_COMPOSE) exec $(DB_SERVICE) mysql -u$(DB_USER) -p$(DB_PASSWORD) $(DB_NAME) < $(DB_DUMP_FILE) 2>/dev/null || true; \
		echo "Database restored from $(DB_DUMP_FILE)."; \
	fi
	@echo "Verifying table $(DB_TABLE_PREFIX)options exists..."
	@while ! $(DOCKER_COMPOSE) exec $(DB_SERVICE) mysql -u$(DB_USER) -p$(DB_PASSWORD) -e "SELECT 1 FROM $(DB_TABLE_PREFIX)options LIMIT 1;" $(DB_NAME) 2>/dev/null; do \
		echo "Table $(DB_TABLE_PREFIX)options not found. Retrying..."; \
		sleep 2; \
	done
	@$(MAKE) update-siteurl
	@docker exec -it usagcd_net_wordpress sh -c "chown -R www-data:www-data wp-content && chmod -R 775 wp-content"
#	@if ! getent group 82 >/dev/null; then sudo groupadd -g 82 containerwww; fi && if ! groups $USER | grep -qw containerwww; then sudo usermod -a -G containerwww $USER; fi
	@echo "Local environment has been setup successfully."

# 2. Export DB: dumps the database to db_dump.sql
export-db:
	@$(DOCKER_COMPOSE) exec $(DB_SERVICE) mysqldump -u$(DB_USER) -p$(DB_PASSWORD) $(DB_NAME) > $(DB_DUMP_FILE)
	@echo "Database exported to $(DB_DUMP_FILE)."

# 3. Update siteurl and home
update-siteurl:
	@$(DOCKER_COMPOSE) exec -e MYSQL_PWD="$(DB_PASSWORD)" $(DB_SERVICE) mysql -u$(DB_USER) $(DB_NAME) -e "UPDATE $(DB_TABLE_PREFIX)options SET option_value = 'http://localhost:8082' WHERE option_name IN ('siteurl','home');"
	@echo "Updated siteurl and home."

# 4. Revert siteurl and home
revert-siteurl:
	@$(DOCKER_COMPOSE) exec -e MYSQL_PWD="$(DB_PASSWORD)" $(DB_SERVICE) mysql -u$(DB_USER) $(DB_NAME) -e "UPDATE $(DB_TABLE_PREFIX)options SET option_value = 'https://usagcd.net' WHERE option_name IN ('siteurl','home');"
	@echo "Reverted siteurl and home."

# 5. Stop local environment
stop:
	$(DOCKER_COMPOSE) down -v
	@echo "Stopped containers and removed volumes."

# 6. Commit & Push: Exports DB, then commits & pushes
push:
	@if ! $(DOCKER_COMPOSE) ps $(DB_SERVICE) | grep -q "Up"; then \
		echo "Error: The local environment is not running."; \
		echo "Please start the environment first using:"; \
		echo "    make setup"; \
		echo "Then re-run this command."; \
		exit 1; \
	fi	
	@$(DOCKER_COMPOSE) exec $(DB_SERVICE) mysql -uroot -p'$(MYSQL_ROOT_PASSWORD)' -e "GRANT PROCESS ON *.* TO '$(DB_USER)'@'%'; FLUSH PRIVILEGES;"
	@$(MAKE) revert-siteurl
	@echo "Reverting siteurl and home..."
	@$(MAKE) export-db
	@read -p "Enter commit message: " msg; \
	git add .; \
	git commit -m "$$msg"; \
	git push origin master
	@echo "Code and DB dump have been committed and pushed successfully."

# 7. Pull code from remote
pull:
	@git pull origin master
	@echo "Code has been pulled successfully."

# make clean to remove the image
clean:
	@docker rmi -f $(shell docker images -q usagcd-wordpress)
	@echo "Removed the image."

# 8. Help: displays available commands
help:
	@echo "Available commands:"
	@echo "  make pull           - Pull code from remote"
	@echo "  make setup          - Setup local environment"
	@echo "  make push           - Export DB, then commit & push"
	@echo "  make stop           - Stop local environment"
	@echo "  make clean          - Remove the image"
	@echo "  make update-siteurl - Update siteurl and home to http://localhost:8082"
	@echo "  make revert-siteurl - Revert siteurl and home to https://usagcd.net"
	@echo "  make help           - Display available commands"

# 9. Default: displays help
.DEFAULT_GOAL := help