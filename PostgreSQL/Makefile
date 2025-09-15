# PostgreSQL Local Development Environment Makefile
# This Makefile provides convenient commands for managing PostgreSQL single node and cluster setups

.PHONY: help single-up single-down cluster-up cluster-down status logs clean
.PHONY: backup restore monitor test-replication
.PHONY: connect-single connect-primary connect-replica1 connect-replica2
.PHONY: connect-lb-write connect-lb-read pgadmin haproxy-stats
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
	@echo "$(YELLOW)PostgreSQL Local Development Environment$(NC)"
	@echo "=========================================="
	@echo
	@awk 'BEGIN {FS = ":.*##"; printf "Usage:\n  make $(BLUE)<target>$(NC)\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  $(BLUE)%-20s$(NC) %s\n", $$1, $$2 } /^##@/ { printf "\n$(YELLOW)%s$(NC)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Single Node Operations
single-up: ## Start single PostgreSQL node with pgAdmin
	@echo "$(GREEN)Starting single PostgreSQL node...$(NC)"
	docker-compose -f $(COMPOSE_FILE_SINGLE) up -d
	@echo "$(GREEN)Single node started successfully!$(NC)"
	@echo "PostgreSQL: localhost:5432"
	@echo "pgAdmin: http://localhost:8080"

single-down: ## Stop single PostgreSQL node
	@echo "$(YELLOW)Stopping single PostgreSQL node...$(NC)"
	docker-compose -f $(COMPOSE_FILE_SINGLE) down
	@echo "$(GREEN)Single node stopped!$(NC)"

single-restart: ## Restart single PostgreSQL node
	@echo "$(YELLOW)Restarting single PostgreSQL node...$(NC)"
	docker-compose -f $(COMPOSE_FILE_SINGLE) restart
	@echo "$(GREEN)Single node restarted!$(NC)"

##@ Cluster Operations
cluster-up: ## Start PostgreSQL cluster with replicas and load balancer
	@echo "$(GREEN)Starting PostgreSQL cluster...$(NC)"
	docker-compose -f $(COMPOSE_FILE_CLUSTER) up -d
	@echo "$(GREEN)Cluster started successfully!$(NC)"
	@echo "Primary: localhost:5432"
	@echo "Replica 1: localhost:5433"
	@echo "Replica 2: localhost:5434"
	@echo "Load Balancer (Write): localhost:5430"
	@echo "Load Balancer (Read): localhost:5431"
	@echo "HAProxy Stats: http://localhost:8404/stats"
	@echo "pgAdmin: http://localhost:8080"

cluster-down: ## Stop PostgreSQL cluster
	@echo "$(YELLOW)Stopping PostgreSQL cluster...$(NC)"
	docker-compose -f $(COMPOSE_FILE_CLUSTER) down
	@echo "$(GREEN)Cluster stopped!$(NC)"

cluster-restart: ## Restart PostgreSQL cluster
	@echo "$(YELLOW)Restarting PostgreSQL cluster...$(NC)"
	docker-compose -f $(COMPOSE_FILE_CLUSTER) restart
	@echo "$(GREEN)Cluster restarted!$(NC)"

##@ Status and Monitoring
status: ## Show status of all services
	@echo "$(BLUE)=== Single Node Status ===$(NC)"
	@docker-compose -f $(COMPOSE_FILE_SINGLE) ps 2>/dev/null || echo "Single node not running"
	@echo
	@echo "$(BLUE)=== Cluster Status ===$(NC)"
	@docker-compose -f $(COMPOSE_FILE_CLUSTER) ps 2>/dev/null || echo "Cluster not running"

logs: ## Show logs from all services
	@echo "$(BLUE)Choose log source:$(NC)"
	@echo "1. Single node"
	@echo "2. Cluster"
	@echo "3. Specific service"
	@read -p "Enter choice (1-3): " choice; \
	case $$choice in \
		1) docker-compose -f $(COMPOSE_FILE_SINGLE) logs -f ;; \
		2) docker-compose -f $(COMPOSE_FILE_CLUSTER) logs -f ;; \
		3) read -p "Enter service name: " service; \
		   if docker ps | grep -q "$$service"; then \
		       docker logs -f "$$service"; \
		   else \
		       echo "$(RED)Service $$service not found$(NC)"; \
		   fi ;; \
		*) echo "$(RED)Invalid choice$(NC)" ;; \
	esac

logs-single: ## Show logs from single node
	docker-compose -f $(COMPOSE_FILE_SINGLE) logs -f

logs-cluster: ## Show logs from cluster
	docker-compose -f $(COMPOSE_FILE_CLUSTER) logs -f

logs-primary: ## Show logs from primary node
	docker-compose -f $(COMPOSE_FILE_CLUSTER) logs -f postgres-primary

logs-replica1: ## Show logs from replica 1
	docker-compose -f $(COMPOSE_FILE_CLUSTER) logs -f postgres-replica-1

logs-replica2: ## Show logs from replica 2
	docker-compose -f $(COMPOSE_FILE_CLUSTER) logs -f postgres-replica-2

logs-haproxy: ## Show logs from HAProxy load balancer
	docker-compose -f $(COMPOSE_FILE_CLUSTER) logs -f haproxy

monitor: ## Run comprehensive cluster monitoring
	@echo "$(GREEN)Running cluster monitoring...$(NC)"
	@if [ -f $(SCRIPTS_DIR)/monitor.sh ]; then \
		$(SCRIPTS_DIR)/monitor.sh; \
	else \
		echo "$(RED)Monitor script not found at $(SCRIPTS_DIR)/monitor.sh$(NC)"; \
	fi

monitor-health: ## Check health status only
	@$(SCRIPTS_DIR)/monitor.sh health

monitor-replication: ## Check replication status only
	@$(SCRIPTS_DIR)/monitor.sh replication

monitor-performance: ## Check performance metrics only
	@$(SCRIPTS_DIR)/monitor.sh performance

##@ Database Connections
connect-single: ## Connect to single PostgreSQL node
	@echo "$(GREEN)Connecting to single PostgreSQL node...$(NC)"
	docker-compose -f $(COMPOSE_FILE_SINGLE) exec postgres psql -U postgres -d devdb

connect-primary: ## Connect to primary node
	@echo "$(GREEN)Connecting to primary node...$(NC)"
	docker-compose -f $(COMPOSE_FILE_CLUSTER) exec postgres-primary psql -U postgres -d devdb

connect-replica1: ## Connect to replica 1
	@echo "$(GREEN)Connecting to replica 1...$(NC)"
	docker-compose -f $(COMPOSE_FILE_CLUSTER) exec postgres-replica-1 psql -U postgres -d devdb

connect-replica2: ## Connect to replica 2
	@echo "$(GREEN)Connecting to replica 2...$(NC)"
	docker-compose -f $(COMPOSE_FILE_CLUSTER) exec postgres-replica-2 psql -U postgres -d devdb

connect-lb-write: ## Connect via load balancer (write port)
	@echo "$(GREEN)Connecting via load balancer (write)...$(NC)"
	docker run --rm -it --network local-dev_postgres_cluster_network postgres:16-alpine psql -h haproxy -p 5430 -U postgres -d devdb

connect-lb-read: ## Connect via load balancer (read port)
	@echo "$(GREEN)Connecting via load balancer (read)...$(NC)"
	docker run --rm -it --network local-dev_postgres_cluster_network postgres:16-alpine psql -h haproxy -p 5431 -U postgres -d devdb

##@ Web Interfaces
pgadmin: ## Open pgAdmin in browser
	@echo "$(GREEN)Opening pgAdmin...$(NC)"
	@if command -v xdg-open >/dev/null 2>&1; then \
		xdg-open http://localhost:8080; \
	elif command -v open >/dev/null 2>&1; then \
		open http://localhost:8080; \
	else \
		echo "pgAdmin URL: http://localhost:8080"; \
		echo "Email: admin@localhost.com"; \
		echo "Password: admin123"; \
	fi

haproxy-stats: ## Open HAProxy statistics in browser
	@echo "$(GREEN)Opening HAProxy statistics...$(NC)"
	@if command -v xdg-open >/dev/null 2>&1; then \
		xdg-open http://localhost:8404/stats; \
	elif command -v open >/dev/null 2>&1; then \
		open http://localhost:8404/stats; \
	else \
		echo "HAProxy Stats URL: http://localhost:8404/stats"; \
	fi

##@ Backup and Restore
backup: ## Create database backup
	@echo "$(GREEN)Creating database backup...$(NC)"
	@mkdir -p $(BACKUP_DIR)
	@if [ -f $(SCRIPTS_DIR)/backup.sh ]; then \
		$(SCRIPTS_DIR)/backup.sh; \
	else \
		echo "$(RED)Backup script not found at $(SCRIPTS_DIR)/backup.sh$(NC)"; \
	fi

backup-single: ## Backup single node database
	@echo "$(GREEN)Creating backup from single node...$(NC)"
	@mkdir -p $(BACKUP_DIR)
	@if [ -f $(SCRIPTS_DIR)/backup.sh ]; then \
		$(SCRIPTS_DIR)/backup.sh devdb postgres_dev; \
	else \
		echo "$(RED)Backup script not found$(NC)"; \
	fi

backup-primary: ## Backup primary node database
	@echo "$(GREEN)Creating backup from primary node...$(NC)"
	@mkdir -p $(BACKUP_DIR)
	@if [ -f $(SCRIPTS_DIR)/backup.sh ]; then \
		$(SCRIPTS_DIR)/backup.sh devdb postgres_primary; \
	else \
		echo "$(RED)Backup script not found$(NC)"; \
	fi

restore: ## Restore database from backup
	@echo "$(YELLOW)Available backup files:$(NC)"
	@ls -la $(BACKUP_DIR)/ 2>/dev/null || echo "No backup files found"
	@read -p "Enter backup file path: " backup_file; \
	if [ -f "$$backup_file" ]; then \
		if [ -f $(SCRIPTS_DIR)/restore.sh ]; then \
			$(SCRIPTS_DIR)/restore.sh "$$backup_file"; \
		else \
			echo "$(RED)Restore script not found at $(SCRIPTS_DIR)/restore.sh$(NC)"; \
		fi; \
	else \
		echo "$(RED)Backup file not found: $$backup_file$(NC)"; \
	fi

list-backups: ## List available backup files
	@echo "$(BLUE)Available backup files:$(NC)"
	@ls -lah $(BACKUP_DIR)/ 2>/dev/null || echo "No backup files found in $(BACKUP_DIR)/"

##@ Testing and Validation
test-replication: ## Run replication tests
	@echo "$(GREEN)Running replication tests...$(NC)"
	@if [ -f $(SCRIPTS_DIR)/test-replication.sh ]; then \
		$(SCRIPTS_DIR)/test-replication.sh; \
	else \
		echo "$(RED)Test script not found at $(SCRIPTS_DIR)/test-replication.sh$(NC)"; \
	fi

test-connections: ## Test all connection methods
	@echo "$(GREEN)Testing database connections...$(NC)"
	@echo "$(BLUE)Testing single node connection...$(NC)"
	@docker-compose -f $(COMPOSE_FILE_SINGLE) exec postgres pg_isready -U postgres || echo "Single node not available"
	@echo "$(BLUE)Testing cluster connections...$(NC)"
	@docker-compose -f $(COMPOSE_FILE_CLUSTER) exec postgres-primary pg_isready -U postgres || echo "Primary not available"
	@docker-compose -f $(COMPOSE_FILE_CLUSTER) exec postgres-replica-1 pg_isready -U postgres || echo "Replica 1 not available"
	@docker-compose -f $(COMPOSE_FILE_CLUSTER) exec postgres-replica-2 pg_isready -U postgres || echo "Replica 2 not available"

performance-test: ## Run basic performance test
	@echo "$(GREEN)Running performance test...$(NC)"
	@read -p "Target (single/primary): " target; \
	case $$target in \
		single) \
			docker-compose -f $(COMPOSE_FILE_SINGLE) exec postgres psql -U postgres -d devdb -c "SELECT 'Performance test on single node' as test; SELECT pg_sleep(1); SELECT NOW();"; \
			;; \
		primary) \
			docker-compose -f $(COMPOSE_FILE_CLUSTER) exec postgres-primary psql -U postgres -d devdb -c "SELECT 'Performance test on primary' as test; SELECT pg_sleep(1); SELECT NOW();"; \
			;; \
		*) echo "$(RED)Invalid target. Use 'single' or 'primary'$(NC)" ;; \
	esac

##@ Maintenance and Cleanup
build: ## Build/rebuild Docker images
	@echo "$(GREEN)Building Docker images...$(NC)"
	docker-compose -f $(COMPOSE_FILE_SINGLE) build
	docker-compose -f $(COMPOSE_FILE_CLUSTER) build

rebuild: ## Force rebuild of all images
	@echo "$(GREEN)Force rebuilding all images...$(NC)"
	docker-compose -f $(COMPOSE_FILE_SINGLE) build --no-cache
	docker-compose -f $(COMPOSE_FILE_CLUSTER) build --no-cache

pull: ## Pull latest PostgreSQL images
	@echo "$(GREEN)Pulling latest images...$(NC)"
	docker-compose -f $(COMPOSE_FILE_SINGLE) pull
	docker-compose -f $(COMPOSE_FILE_CLUSTER) pull

volumes-clean: ## Remove all PostgreSQL volumes (WARNING: DATA LOSS)
	@echo "$(RED)WARNING: This will delete ALL PostgreSQL data!$(NC)"
	@read -p "Are you sure? Type 'yes' to continue: " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		echo "$(YELLOW)Stopping services...$(NC)"; \
		docker-compose -f $(COMPOSE_FILE_SINGLE) down -v 2>/dev/null || true; \
		docker-compose -f $(COMPOSE_FILE_CLUSTER) down -v 2>/dev/null || true; \
		echo "$(GREEN)Volumes cleaned!$(NC)"; \
	else \
		echo "$(GREEN)Operation cancelled$(NC)"; \
	fi

full-clean: volumes-clean ## Complete cleanup including images and networks
	@echo "$(YELLOW)Performing full cleanup...$(NC)"
	docker system prune -f
	@echo "$(GREEN)Full cleanup completed!$(NC)"

clean-logs: ## Clean up container logs
	@echo "$(YELLOW)Cleaning container logs...$(NC)"
	@for container in $$(docker ps -aq); do \
		echo "" > $$(docker inspect --format='{{.LogPath}}' $$container) 2>/dev/null || true; \
	done
	@echo "$(GREEN)Logs cleaned!$(NC)"

##@ Setup and Configuration
setup: ## Initial setup - make scripts executable and create directories
	@echo "$(GREEN)Setting up PostgreSQL development environment...$(NC)"
	chmod +x $(SCRIPTS_DIR)/*.sh 2>/dev/null || echo "Scripts directory not found"
	chmod +x init-scripts/*.sh 2>/dev/null || echo "Init scripts not found"
	chmod +x cluster-init-scripts/*.sh 2>/dev/null || echo "Cluster init scripts not found"
	chmod +x setup-replica.sh 2>/dev/null || echo "Replica setup script not found"
	mkdir -p $(BACKUP_DIR)
	@echo "$(GREEN)Setup completed!$(NC)"

check-env: ## Check environment configuration
	@echo "$(BLUE)Environment Configuration:$(NC)"
	@if [ -f .env ]; then \
		echo "$(GREEN)✓ .env file found$(NC)"; \
		grep -E "^[A-Z_]+" .env | head -10; \
	else \
		echo "$(RED)✗ .env file not found$(NC)"; \
		echo "Copy .env.example to .env and customize"; \
	fi

check-scripts: ## Check if all required scripts are available
	@echo "$(BLUE)Script Availability:$(NC)"
	@for script in backup.sh restore.sh monitor.sh test-replication.sh; do \
		if [ -f $(SCRIPTS_DIR)/$$script ]; then \
			echo "$(GREEN)✓ $$script$(NC)"; \
		else \
			echo "$(RED)✗ $$script$(NC)"; \
		fi; \
	done

show-config: ## Show current configuration
	@echo "$(BLUE)Current Configuration:$(NC)"
	@echo "Single Compose File: $(COMPOSE_FILE_SINGLE)"
	@echo "Cluster Compose File: $(COMPOSE_FILE_CLUSTER)"
	@echo "Backup Directory: $(BACKUP_DIR)"
	@echo "Scripts Directory: $(SCRIPTS_DIR)"
	@echo
	@make check-env
	@echo
	@make check-scripts

##@ Quick Actions
dev: single-up ## Quick start for development (single node)

prod-test: cluster-up ## Quick start for production-like testing (cluster)

quick-backup: ## Quick backup with timestamp
	@timestamp=$$(date +"%Y%m%d_%H%M%S"); \
	echo "$(GREEN)Creating quick backup: devdb_$$timestamp$(NC)"; \
	if docker ps | grep -q postgres_dev; then \
		docker exec postgres_dev pg_dump -U postgres devdb | gzip > $(BACKUP_DIR)/devdb_quick_$$timestamp.sql.gz; \
		echo "$(GREEN)Backup saved: $(BACKUP_DIR)/devdb_quick_$$timestamp.sql.gz$(NC)"; \
	elif docker ps | grep -q postgres_primary; then \
		docker exec postgres_primary pg_dump -U postgres devdb | gzip > $(BACKUP_DIR)/devdb_quick_$$timestamp.sql.gz; \
		echo "$(GREEN)Backup saved: $(BACKUP_DIR)/devdb_quick_$$timestamp.sql.gz$(NC)"; \
	else \
		echo "$(RED)No PostgreSQL instance running$(NC)"; \
	fi

health-check: ## Quick health check
	@echo "$(BLUE)Quick Health Check:$(NC)"
	@if docker ps | grep -q postgres_dev; then \
		echo "$(GREEN)✓ Single node running$(NC)"; \
	else \
		echo "$(YELLOW)- Single node not running$(NC)"; \
	fi
	@if docker ps | grep -q postgres_primary; then \
		echo "$(GREEN)✓ Cluster running$(NC)"; \
	else \
		echo "$(YELLOW)- Cluster not running$(NC)"; \
	fi

##@ Information
info: ## Show comprehensive system information
	@echo "$(BLUE)PostgreSQL Development Environment Info$(NC)"
	@echo "======================================"
	@echo "Docker version: $$(docker --version)"
	@echo "Docker Compose version: $$(docker-compose --version)"
	@echo "Current directory: $$(pwd)"
	@echo
	@make show-config
	@echo
	@make health-check
