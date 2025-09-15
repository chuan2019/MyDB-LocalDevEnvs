# MongoDB Local Development Environment Makefile
# This Makefile provides convenient commands for managing MongoDB single node and replica set setups

.PHONY: help single-up single-down cluster-up cluster-down down status logs clean
.PHONY: backup restore monitor test-replica-set init-replica-set
.PHONY: connect-single connect-primary connect-secondary1 connect-secondary2
.PHONY: mongo-express shell-primary shell-secondary1 shell-secondary2
.PHONY: build rebuild volumes-clean full-clean setup

# Default target
.DEFAULT_GOAL := help

# Variables
COMPOSE_FILE_SINGLE := docker-compose.yml
COMPOSE_FILE_CLUSTER := docker-compose-cluster.yml
BACKUP_DIR := ./backups
SCRIPTS_DIR := ./scripts

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
BLUE := \033[0;34m
NC := \033[0m # No Color

##@ Help
help: ## Display this help message
	@echo "$(YELLOW)MongoDB Local Development Environment$(NC)"
	@echo "========================================"
	@echo
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Quick Start Commands
dev: single-up ## Quick start for development (single node)
	@echo "$(GREEN)Development environment started!$(NC)"
	@echo "MongoDB: mongodb://localhost:27017"
	@echo "MongoDB Express: http://localhost:8081"
	@echo "Credentials: admin/admin123"

prod-test: cluster-up init-replica-set ## Quick start for production testing (replica set)
	@echo "$(GREEN)Production test environment started!$(NC)"
	@echo "MongoDB Replica Set: mongodb://localhost:27017,localhost:27018,localhost:27019"
	@echo "MongoDB Express: http://localhost:8081"
	@echo "Credentials: admin/admin123"

##@ Single Node Operations
single-up: ## Start single MongoDB node with MongoDB Express
	@echo "$(BLUE)Starting single MongoDB node...$(NC)"
	@if [ ! -f .env ]; then cp .env.example .env; echo "$(YELLOW)Created .env from .env.example$(NC)"; fi
	@docker-compose -f $(COMPOSE_FILE_SINGLE) up -d
	@echo "$(GREEN)Single node started successfully!$(NC)"
	@echo "MongoDB: mongodb://localhost:$$(grep MONGO_PORT .env | cut -d'=' -f2 | head -1)"
	@echo "MongoDB Express: http://localhost:$$(grep MONGO_EXPRESS_PORT .env | cut -d'=' -f2)"

single-down: ## Stop single MongoDB node
	@echo "$(BLUE)Stopping single MongoDB node...$(NC)"
	@docker-compose -f $(COMPOSE_FILE_SINGLE) down
	@echo "$(GREEN)Single node stopped successfully!$(NC)"

##@ Cluster Operations
cluster-up: ## Start MongoDB replica set cluster
	@echo "$(BLUE)Starting MongoDB replica set cluster...$(NC)"
	@if [ ! -f .env ]; then cp .env.example .env; echo "$(YELLOW)Created .env from .env.example$(NC)"; fi
	@docker-compose -f $(COMPOSE_FILE_CLUSTER) up -d
	@echo "$(GREEN)Cluster started successfully!$(NC)"
	@echo "$(YELLOW)Note: Run 'make init-replica-set' to initialize the replica set$(NC)"

cluster-down: ## Stop MongoDB replica set cluster
	@echo "$(BLUE)Stopping MongoDB replica set cluster...$(NC)"
	@docker-compose -f $(COMPOSE_FILE_CLUSTER) down
	@echo "$(GREEN)Cluster stopped successfully!$(NC)"

init-replica-set: ## Initialize MongoDB replica set (run after cluster-up)
	@echo "$(BLUE)Initializing MongoDB replica set...$(NC)"
	@sleep 10  # Wait for containers to be ready
	@chmod +x $(SCRIPTS_DIR)/init-replica-set.sh
	@$(SCRIPTS_DIR)/init-replica-set.sh
	@echo "$(GREEN)Replica set initialized successfully!$(NC)"

##@ General Operations
down: ## Stop all services (both single and cluster)
	@echo "$(BLUE)Stopping all MongoDB services...$(NC)"
	@docker-compose -f $(COMPOSE_FILE_SINGLE) down 2>/dev/null || true
	@docker-compose -f $(COMPOSE_FILE_CLUSTER) down 2>/dev/null || true
	@echo "$(GREEN)All services stopped!$(NC)"

status: ## Show status of all MongoDB containers
	@echo "$(BLUE)MongoDB Services Status:$(NC)"
	@docker ps --filter "name=mongo" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
	@echo
	@echo "$(BLUE)Health Status:$(NC)"
	@docker ps --filter "name=mongo" --format "{{.Names}}" | xargs -I {} docker inspect {} --format='{{.Name}}: {{.State.Health.Status}}' 2>/dev/null || echo "Health checks not configured"

logs: ## Show logs from all MongoDB services
	@echo "$(BLUE)MongoDB Services Logs:$(NC)"
	@docker-compose -f $(COMPOSE_FILE_SINGLE) logs -f 2>/dev/null || docker-compose -f $(COMPOSE_FILE_CLUSTER) logs -f 2>/dev/null || echo "No services running"

##@ Connection Commands
connect-single: ## Connect to single MongoDB instance
	@echo "$(BLUE)Connecting to single MongoDB instance...$(NC)"
	@docker exec -it mongodb_single mongosh mongodb://admin:$$(grep MONGO_INITDB_ROOT_PASSWORD .env | cut -d'=' -f2)@localhost:27017/admin

connect-primary: ## Connect to MongoDB primary (replica set)
	@echo "$(BLUE)Connecting to MongoDB primary...$(NC)"
	@docker exec -it mongodb_primary mongosh mongodb://admin:$$(grep MONGO_INITDB_ROOT_PASSWORD .env | cut -d'=' -f2)@localhost:27017/admin

connect-secondary1: ## Connect to MongoDB secondary 1 (replica set)
	@echo "$(BLUE)Connecting to MongoDB secondary 1...$(NC)"
	@docker exec -it mongodb_secondary_1 mongosh mongodb://admin:$$(grep MONGO_INITDB_ROOT_PASSWORD .env | cut -d'=' -f2)@localhost:27017/admin

connect-secondary2: ## Connect to MongoDB secondary 2 (replica set)
	@echo "$(BLUE)Connecting to MongoDB secondary 2...$(NC)"
	@docker exec -it mongodb_secondary_2 mongosh mongodb://admin:$$(grep MONGO_INITDB_ROOT_PASSWORD .env | cut -d'=' -f2)@localhost:27017/admin

shell-primary: ## Open shell in MongoDB primary container
	@docker exec -it mongodb_primary bash

shell-secondary1: ## Open shell in MongoDB secondary 1 container
	@docker exec -it mongodb_secondary_1 bash

shell-secondary2: ## Open shell in MongoDB secondary 2 container
	@docker exec -it mongodb_secondary_2 bash

##@ Web UI
mongo-express: ## Open MongoDB Express in browser
	@echo "$(BLUE)Opening MongoDB Express...$(NC)"
	@echo "URL: http://localhost:$$(grep MONGO_EXPRESS_PORT .env | cut -d'=' -f2)"
	@echo "Username: $$(grep MONGO_EXPRESS_USERNAME .env | cut -d'=' -f2)"
	@echo "Password: $$(grep MONGO_EXPRESS_PASSWORD .env | cut -d'=' -f2)"

##@ Backup and Restore
backup: ## Create backup of all databases
	@echo "$(BLUE)Creating MongoDB backup...$(NC)"
	@mkdir -p $(BACKUP_DIR)
	@chmod +x $(SCRIPTS_DIR)/backup.sh
	@$(SCRIPTS_DIR)/backup.sh
	@echo "$(GREEN)Backup completed successfully!$(NC)"

restore: ## Restore from backup (Usage: make restore BACKUP_PATH=/path/to/backup)
	@echo "$(BLUE)Restoring MongoDB from backup...$(NC)"
	@if [ -z "$(BACKUP_PATH)" ]; then \
		echo "$(RED)Error: BACKUP_PATH not specified. Usage: make restore BACKUP_PATH=/path/to/backup$(NC)"; \
		exit 1; \
	fi
	@chmod +x $(SCRIPTS_DIR)/restore.sh
	@$(SCRIPTS_DIR)/restore.sh $(BACKUP_PATH)
	@echo "$(GREEN)Restore completed successfully!$(NC)"

##@ Monitoring and Testing
monitor: ## Monitor replica set status and performance
	@echo "$(BLUE)Monitoring MongoDB replica set...$(NC)"
	@chmod +x $(SCRIPTS_DIR)/monitor.sh
	@$(SCRIPTS_DIR)/monitor.sh

test-replica-set: ## Test replica set functionality
	@echo "$(BLUE)Testing MongoDB replica set...$(NC)"
	@chmod +x $(SCRIPTS_DIR)/test-replica-set.sh
	@$(SCRIPTS_DIR)/test-replica-set.sh

##@ Maintenance
volumes-clean: ## Remove all MongoDB data volumes (DESTRUCTIVE)
	@echo "$(RED)WARNING: This will delete all MongoDB data!$(NC)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker volume rm mongodb_data mongodb_primary_data mongodb_secondary1_data mongodb_secondary2_data mongoexpress_data 2>/dev/null || true; \
		echo "$(GREEN)Volumes cleaned successfully!$(NC)"; \
	else \
		echo "$(YELLOW)Operation cancelled.$(NC)"; \
	fi

clean: down volumes-clean ## Stop all services and clean volumes (DESTRUCTIVE)

full-clean: clean ## Complete cleanup including images (DESTRUCTIVE)
	@echo "$(RED)WARNING: This will remove all MongoDB containers, volumes, and images!$(NC)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker rmi mongo:7.0 mongo-express:latest 2>/dev/null || true; \
		echo "$(GREEN)Full cleanup completed!$(NC)"; \
	else \
		echo "$(YELLOW)Operation cancelled.$(NC)"; \
	fi

rebuild: down ## Rebuild all containers
	@echo "$(BLUE)Rebuilding MongoDB containers...$(NC)"
	@docker-compose -f $(COMPOSE_FILE_SINGLE) build --no-cache
	@docker-compose -f $(COMPOSE_FILE_CLUSTER) build --no-cache
	@echo "$(GREEN)Rebuild completed!$(NC)"

##@ Setup
setup: ## Initial setup - copy example files and create directories
	@echo "$(BLUE)Setting up MongoDB development environment...$(NC)"
	@mkdir -p $(BACKUP_DIR) $(SCRIPTS_DIR) data init-scripts
	@if [ ! -f .env ]; then cp .env.example .env; echo "$(GREEN)Created .env from .env.example$(NC)"; fi
	@chmod +x $(SCRIPTS_DIR)/*.sh 2>/dev/null || true
	@echo "$(GREEN)Setup completed! Run 'make dev' to start development environment.$(NC)"

##@ Information
env-info: ## Display current environment configuration
	@echo "$(BLUE)Current Environment Configuration:$(NC)"
	@echo "=================================="
	@if [ -f .env ]; then \
		cat .env | grep -v '^#' | grep -v '^$$' | sort; \
	else \
		echo "$(YELLOW)No .env file found. Run 'make setup' first.$(NC)"; \
	fi

ports-info: ## Display port information
	@echo "$(BLUE)MongoDB Port Configuration:$(NC)"
	@echo "============================"
	@if [ -f .env ]; then \
		echo "Single Node MongoDB: $$(grep MONGO_PORT .env | cut -d'=' -f2)"; \
		echo "Primary (Cluster): $$(grep MONGO_PRIMARY_PORT .env | cut -d'=' -f2)"; \
		echo "Secondary 1 (Cluster): $$(grep MONGO_SECONDARY1_PORT .env | cut -d'=' -f2)"; \
		echo "Secondary 2 (Cluster): $$(grep MONGO_SECONDARY2_PORT .env | cut -d'=' -f2)"; \
		echo "MongoDB Express: $$(grep MONGO_EXPRESS_PORT .env | cut -d'=' -f2)"; \
	else \
		echo "$(YELLOW)No .env file found. Run 'make setup' first.$(NC)"; \
	fi
