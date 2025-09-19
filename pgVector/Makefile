.PHONY: help build up down restart logs backup restore monitor test-replication test-vectors

.DEFAULT_GOAL := help

help: ## Show this help message
	@echo "pgVector Local Development Environment"
	@echo "====================================="
	@echo ""
	@echo "Available commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'
	@echo ""

build: ## Build the Docker images
	docker-compose build

up: ## Start the PostgreSQL containers
	docker-compose up -d

down: ## Stop and remove the containers
	docker-compose down

restart: ## Restart the containers
	docker-compose restart

logs: ## Show container logs
	docker-compose logs -f

backup: ## Create a database backup
	scripts/backup.sh

restore: ## Restore database from backup (usage: make restore BACKUP_FILE=filename)
	scripts/restore.sh

monitor: ## Monitor PostgreSQL health status
	scripts/monitor.sh

test-replication: ## Test PostgreSQL replication setup
	scripts/test-replication.sh

test-vectors: ## Run vector similarity search tests
	scripts/test-vector-similarity.sh