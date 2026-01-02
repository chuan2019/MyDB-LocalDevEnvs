.PHONY: up down status logs clean help up-single up-cluster down-single down-cluster status-single status-cluster

# Default target - single node mode
up: up-single

down: down-single

status: status-single

# Single node mode commands
up-single:
	@echo "Starting MemGraph (Single Node)..."
	docker-compose -p memgraph-single -f docker/docker-compose.single.yml up -d
	@echo "MemGraph (Single Node) is starting..."
	@echo "Access MemGraph Lab at: http://localhost:3000"
	@echo "Bolt connection: bolt://localhost:7687"

down-single:
	@echo "Stopping single node services..."
	docker-compose -p memgraph-single -f docker/docker-compose.single.yml down

status-single:
	@echo "Single Node Service Status:"
	docker-compose -p memgraph-single -f docker/docker-compose.single.yml ps

# Cluster mode commands
up-cluster:
	@echo "Starting MemGraph Cluster (3 nodes)..."
	docker-compose -p memgraph-cluster -f docker/docker-compose.cluster.yml up -d
	@echo "MemGraph Cluster is starting..."
	@echo "Node 1 - Lab: http://localhost:3000 | Bolt: bolt://localhost:7687"
	@echo "Node 2 - Lab: http://localhost:3001 | Bolt: bolt://localhost:7688"
	@echo "Node 3 - Lab: http://localhost:3002 | Bolt: bolt://localhost:7689"

down-cluster:
	@echo "Stopping cluster services..."
	docker-compose -p memgraph-cluster -f docker/docker-compose.cluster.yml down

status-cluster:
	@echo "Cluster Service Status:"
	docker-compose -p memgraph-cluster -f docker/docker-compose.cluster.yml ps

logs:
	docker-compose -f docker/docker-compose.single.yml logs

logs-cluster:
	docker-compose -f docker/docker-compose.cluster.yml logs

clean:
	@echo "Cleaning up MemGraph containers and volumes..."
	docker-compose -p memgraph-single -f docker/docker-compose.single.yml down -v
	docker-compose -p memgraph-cluster -f docker/docker-compose.cluster.yml down -v
	docker volume prune -f

setup:
	@echo "Running setup script..."
	@cd scripts && chmod +x setup.sh && ./setup.sh

help:
	@echo "Available targets:"
	@echo "  setup        - Run initial setup"
	@echo "  up           - Start MemGraph (single node)"
	@echo "  up-cluster   - Start MemGraph cluster (3 nodes)"
	@echo "  down         - Stop single node"
	@echo "  down-cluster - Stop cluster"
	@echo "  status       - Show status (single node)"
	@echo "  status-cluster - Show status (cluster)"
	@echo "  logs         - Show logs (single node)"
	@echo "  logs-cluster - Show logs (cluster)"
	@echo "  clean        - Remove containers and volumes"
	@echo "  help         - Show this help message"
