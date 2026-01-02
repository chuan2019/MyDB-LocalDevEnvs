.PHONY: up down status logs clean help up-single up-cluster down-single down-cluster status-single status-cluster notebook venv install

# Default target - single node mode
up: up-single

down: down-single

status: status-single

# Single node mode commands
up-single:
	@echo "Starting ScyllaDB (Single Node)..."
	docker-compose -p scylla-single -f docker/docker-compose.single.yml up -d
	@echo "ScyllaDB (Single Node) is starting..."
	@echo "CQL connection: 127.0.0.1:9042"
	@echo "Waiting for ScyllaDB to be ready (this may take 30-60 seconds)..."

down-single:
	@echo "Stopping single node services..."
	docker-compose -p scylla-single -f docker/docker-compose.single.yml down

status-single:
	@echo "Single Node Service Status:"
	docker-compose -p scylla-single -f docker/docker-compose.single.yml ps

# Cluster mode commands
up-cluster:
	@echo "Starting ScyllaDB Cluster (3 nodes)..."
	docker-compose -p scylla-cluster -f docker/docker-compose.cluster.yml up -d
	@echo "ScyllaDB Cluster is starting..."
	@echo "Node 1 CQL: 127.0.0.1:9042"
	@echo "Node 2 CQL: 127.0.0.1:9043"
	@echo "Node 3 CQL: 127.0.0.1:9044"
	@echo "Waiting for cluster to form (this may take 1-2 minutes)..."

down-cluster:
	@echo "Stopping cluster services..."
	docker-compose -p scylla-cluster -f docker/docker-compose.cluster.yml down

status-cluster:
	@echo "Cluster Service Status:"
	docker-compose -p scylla-cluster -f docker/docker-compose.cluster.yml ps

logs:
	docker-compose -f docker/docker-compose.single.yml logs

logs-cluster:
	docker-compose -f docker/docker-compose.cluster.yml logs

clean:
	@echo "Cleaning up ScyllaDB containers and volumes..."
	docker-compose -p scylla-single -f docker/docker-compose.single.yml down -v
	docker-compose -p scylla-cluster -f docker/docker-compose.cluster.yml down -v
	docker volume prune -f

setup:
	@echo "Running setup script..."
	@cd scripts && chmod +x setup.sh && ./setup.sh

# Python virtual environment commands
venv:
	@echo "Creating Python virtual environment with uv..."
	@if command -v uv >/dev/null 2>&1; then \
		uv venv; \
		echo "Virtual environment created at .venv"; \
		echo "Activate with: source .venv/bin/activate"; \
	else \
		echo "Error: uv not found. Install with: curl -LsSf https://astral.sh/uv/install.sh | sh"; \
		exit 1; \
	fi

install:
	@echo "Installing Python dependencies..."
	@if [ ! -d ".venv" ]; then \
		echo "Error: Virtual environment not found. Run 'make venv' first."; \
		exit 1; \
	fi
	@if command -v uv >/dev/null 2>&1; then \
		uv pip install -e .; \
		echo "Dependencies installed successfully"; \
	else \
		echo "Error: uv not found."; \
		exit 1; \
	fi

notebook:
	@echo "Starting Jupyter Lab..."
	@if [ ! -d ".venv" ]; then \
		echo "Error: Virtual environment not found. Run 'make setup' first."; \
		exit 1; \
	fi
	@if [ ! -f ".venv/bin/jupyter" ]; then \
		echo "Error: Jupyter not installed. Run 'make install' first."; \
		exit 1; \
	fi
	@echo "Opening Jupyter Lab in notebooks directory..."
	@.venv/bin/jupyter lab notebooks/

help:
	@echo "Available targets:"
	@echo "  setup        - Run initial setup (creates venv and installs deps)"
	@echo "  up           - Start ScyllaDB (single node)"
	@echo "  up-cluster   - Start ScyllaDB cluster (3 nodes)"
	@echo "  down         - Stop single node"
	@echo "  down-cluster - Stop cluster"
	@echo "  status       - Show status (single node)"
	@echo "  status-cluster - Show status (cluster)"
	@echo "  logs         - Show logs (single node)"
	@echo "  logs-cluster - Show logs (cluster)"
	@echo "  venv         - Create Python virtual environment"
	@echo "  install      - Install Python dependencies"
	@echo "  notebook     - Start Jupyter Lab"
	@echo "  clean        - Remove containers and volumes"
	@echo "  help         - Show this help message"
