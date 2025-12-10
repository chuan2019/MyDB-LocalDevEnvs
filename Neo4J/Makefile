.PHONY: up down status logs clean help up-single up-cluster down-single down-cluster status-single status-cluster

# Default target - single node mode
up: up-single

down: down-single

status: status-single

# Single node mode commands
up-single:
	@echo "Starting Neo4J (Single Node)..."
	docker-compose -p neo4j-single -f docker/docker-compose.single.yml up -d
	@echo "Neo4J (Single Node) is starting..."


down-single:
	@echo "Stopping single node services..."
	docker-compose -p neo4j-single -f docker/docker-compose.single.yml down

status-single:
	@echo "Single Node Service Status:"
	docker-compose -p neo4j-single -f docker/docker-compose.single.yml ps

# Cluster mode commands
up-cluster:
	@echo "Starting Neo4J Cluster (3 nodes)..."
	docker-compose -p neo4j-cluster -f docker/docker-compose.cluster.yml up -d
	@echo "Neo4J Cluster is starting..."

down-cluster:
	@echo "Stopping cluster services..."
	docker-compose -p neo4j-cluster -f docker/docker-compose.cluster.yml down

status-cluster:
	@echo "Cluster Service Status:"
	docker-compose -p neo4j-cluster -f docker/docker-compose.cluster.yml ps

logs:
	docker-compose -f docker/docker-compose.single.yml logs

clean:
	docker-compose -f docker/docker-compose.single.yml down -v
	docker-compose -f docker/docker-compose.cluster.yml down -v
	docker volume prune -f

help:
	@echo "Available targets:"
	@echo "  up           - Start Neo4J (single node)"
	@echo "  up-cluster   - Start Neo4J cluster (3 nodes)"
	@echo "  down         - Stop single node"
	@echo "  down-cluster - Stop cluster"
	@echo "  status       - Show status (single node)"
	@echo "  status-cluster - Show status (cluster)"
	@echo "  logs         - Show logs"
	@echo "  clean        - Remove containers and volumes"
	@echo "  help         - Show this help message"
