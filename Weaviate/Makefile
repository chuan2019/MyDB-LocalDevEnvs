.PHONY: up down status logs clean help up-single up-cluster down-single down-cluster status-single status-cluster

# Default target - single node mode
up: up-single

# Single node mode commands
up-single: start-services-single wait-for-models-single

start-services-single:
	@echo "Starting Weaviate (Single Node) and Ollama services..."
	docker-compose -p weaviate-single -f docker/docker-compose.single.yml up -d weaviate ollama
	@echo "Waiting for Ollama to be ready..."
	@sleep 15
	@echo "Starting model initialization..."
	docker-compose -p weaviate-single -f docker/docker-compose.single.yml up -d ollama-init

wait-for-models-single:
	@echo "Waiting for model pulling to complete..."
	@while [ "$$(docker-compose -p weaviate-single -f docker/docker-compose.single.yml ps -q ollama-init 2>/dev/null)" != "" ] && [ "$$(docker inspect -f '{{.State.Status}}' ollama-init-single 2>/dev/null)" != "exited" ]; do \
		echo "Models are being downloaded... (checking again in 10s)"; \
		docker-compose -p weaviate-single -f docker/docker-compose.single.yml logs --tail=5 ollama-init | grep -E "(Pulling|downloading|verifying)" || true; \
		sleep 10; \
	done
	@if [ "$$(docker inspect -f '{{.State.ExitCode}}' ollama-init-single 2>/dev/null)" = "0" ]; then \
		echo "Model pulling completed successfully!"; \
		echo "Single node setup is ready!"; \
		echo ""; \
		echo "Service Status:"; \
		docker-compose -p weaviate-single -f docker/docker-compose.single.yml ps; \
		echo ""; \
		echo "Access URLs:"; \
		echo "   Weaviate: http://localhost:8080"; \
		echo "   Ollama: http://localhost:11435"; \
	else \
		echo "Model pulling failed!"; \
		echo "Checking logs..."; \
		docker-compose -p weaviate-single -f docker/docker-compose.single.yml logs ollama-init; \
		exit 1; \
	fi

down-single:
	@echo "Stopping single node services..."
	docker-compose -p weaviate-single -f docker/docker-compose.single.yml down

status-single:
	@echo "Single Node Service Status:"
	docker-compose -p weaviate-single -f docker/docker-compose.single.yml ps

# Cluster mode commands
up-cluster: start-services-cluster wait-for-models-cluster

start-services-cluster:
	@echo "Starting Weaviate Cluster (3 nodes) and Ollama services..."
	docker-compose -p weaviate-cluster -f docker/docker-compose.cluster.yml up -d weaviate-node1 weaviate-node2 weaviate-node3 ollama
	@echo "Waiting for cluster nodes to start and Ollama to be ready..."
	@sleep 20
	@echo "Starting model initialization..."
	docker-compose -p weaviate-cluster -f docker/docker-compose.cluster.yml up -d ollama-init

wait-for-models-cluster:
	@echo "Waiting for model pulling to complete..."
	@while [ "$$(docker-compose -p weaviate-cluster -f docker/docker-compose.cluster.yml ps -q ollama-init 2>/dev/null)" != "" ] && [ "$$(docker inspect -f '{{.State.Status}}' ollama-init-cluster 2>/dev/null)" != "exited" ]; do \
		echo "Models are being downloaded... (checking again in 10s)"; \
		docker-compose -p weaviate-cluster -f docker/docker-compose.cluster.yml logs --tail=5 ollama-init | grep -E "(Pulling|downloading|verifying)" || true; \
		sleep 10; \
	done
	@if [ "$$(docker inspect -f '{{.State.ExitCode}}' ollama-init-cluster 2>/dev/null)" = "0" ]; then \
		echo "Model pulling completed successfully!"; \
		echo "Cluster setup is ready!"; \
		echo ""; \
		echo "Service Status:"; \
		docker-compose -p weaviate-cluster -f docker/docker-compose.cluster.yml ps; \
		echo ""; \
		echo "Access URLs:"; \
		echo "   Weaviate Node 1: http://localhost:8080"; \
		echo "   Weaviate Node 2: http://localhost:8081"; \
		echo "   Weaviate Node 3: http://localhost:8082"; \
		echo "   Ollama: http://localhost:11435"; \
		echo ""; \
		echo "You can connect to any node - the cluster will distribute requests automatically"; \
	else \
		echo "Model pulling failed!"; \
		echo "Checking logs..."; \
		docker-compose -p weaviate-cluster -f docker/docker-compose.cluster.yml logs ollama-init; \
		exit 1; \
	fi

down-cluster:
	@echo "Stopping cluster services..."
	docker-compose -p weaviate-cluster -f docker/docker-compose.cluster.yml down

status-cluster:
	@echo "Cluster Service Status:"
	docker-compose -p weaviate-cluster -f docker/docker-compose.cluster.yml ps

# Generic commands that work with the current mode
down:
	@echo "Stopping all services..."
	@docker-compose -p weaviate-single -f docker/docker-compose.single.yml down 2>/dev/null || true
	@docker-compose -p weaviate-cluster -f docker/docker-compose.cluster.yml down 2>/dev/null || true

status:
	@echo "Checking all possible services..."
	@echo "--- Single Node Services ---"
	@docker-compose -p weaviate-single -f docker/docker-compose.single.yml ps 2>/dev/null || echo "No single node services running"
	@echo ""
	@echo "--- Cluster Services ---"
	@docker-compose -p weaviate-cluster -f docker/docker-compose.cluster.yml ps 2>/dev/null || echo "No cluster services running"

# Show logs for all services
logs:
	@echo "Showing logs for all running services..."
	@docker-compose -p weaviate-single -f docker/docker-compose.single.yml logs -f 2>/dev/null &
	@docker-compose -p weaviate-cluster -f docker/docker-compose.cluster.yml logs -f 2>/dev/null || true

# Show logs for specific service types
logs-weaviate:
	@echo "Showing Weaviate logs..."
	@docker logs weaviate-single -f 2>/dev/null || docker logs weaviate-node1 -f 2>/dev/null || echo "No Weaviate containers running"

logs-weaviate-cluster:
	@echo "Showing cluster Weaviate logs..."
	@docker logs weaviate-node1 -f 2>/dev/null &
	@docker logs weaviate-node2 -f 2>/dev/null &
	@docker logs weaviate-node3 -f 2>/dev/null || true

logs-ollama:
	@docker logs ollama-single -f 2>/dev/null || docker logs ollama-cluster -f 2>/dev/null || echo "No Ollama containers running"

logs-init:
	@docker logs ollama-init-single -f 2>/dev/null || docker logs ollama-init-cluster -f 2>/dev/null || echo "No ollama-init containers running"

# Clean up everything (including volumes)
clean:
	@echo "Cleaning up all containers and volumes..."
	@docker-compose -p weaviate-single -f docker/docker-compose.single.yml down -v 2>/dev/null || true
	@docker-compose -p weaviate-cluster -f docker/docker-compose.cluster.yml down -v 2>/dev/null || true
	@docker system prune -f

clean-single:
	@echo "Cleaning up single node containers and volumes..."
	docker-compose -p weaviate-single -f docker/docker-compose.single.yml down -v

clean-cluster:
	@echo "Cleaning up cluster containers and volumes..."
	docker-compose -p weaviate-cluster -f docker/docker-compose.cluster.yml down -v

# Restart services
restart-single: down-single up-single
restart-cluster: down-cluster up-cluster
restart: down up

# Check if models are available
check-models:
	@echo "Checking available models..."
	@curl -s http://localhost:11435/api/tags | jq '.models[].name' 2>/dev/null || echo "Cannot connect to Ollama or jq not installed"

# Check cluster status (only works in cluster mode)
check-cluster:
	@echo "Checking cluster status..."
	@echo "Node 1 (port 8080):"
	@curl -s http://localhost:8080/v1/nodes 2>/dev/null | jq '.' || echo "Cannot connect to node 1"
	@echo ""
	@echo "Node 2 (port 8081):"
	@curl -s http://localhost:8081/v1/nodes 2>/dev/null | jq '.' || echo "Cannot connect to node 2"
	@echo ""
	@echo "Node 3 (port 8082):"
	@curl -s http://localhost:8082/v1/nodes 2>/dev/null | jq '.' || echo "Cannot connect to node 3"

# Dataset upload commands
upload-dataset:
	@if [ -z "$(FILE)" ]; then \
		echo "Error: FILE parameter is required"; \
		echo "Usage: make upload-dataset FILE=/path/to/dataset.json"; \
		echo "       make upload-dataset FILE=/path/to/dataset.json CLASS=MyClass"; \
		echo "       make upload-dataset FILE=/path/to/dataset.json URL=http://localhost:8081"; \
		exit 1; \
	fi
	@echo "Uploading dataset: $(FILE)"
	@python3 scripts/upload_dataset.py "$(FILE)" $(if $(CLASS),--class-name "$(CLASS)") $(if $(URL),--weaviate-url "$(URL)")

upload-to-cluster:
	@if [ -z "$(FILE)" ]; then \
		echo "Error: FILE parameter is required"; \
		echo "Usage: make upload-to-cluster FILE=/path/to/dataset.json"; \
		echo "       make upload-to-cluster FILE=/path/to/dataset.json CLASS=MyClass"; \
		echo "       make upload-to-cluster FILE=/path/to/dataset.json NODE=2"; \
		exit 1; \
	fi
	@NODE_PORT=$$(if [ "$(NODE)" = "2" ]; then echo "8081"; elif [ "$(NODE)" = "3" ]; then echo "8082"; else echo "8080"; fi); \
	echo "Uploading dataset to cluster node $(if $(NODE),$(NODE),1) (port $$NODE_PORT): $(FILE)"; \
	python3 scripts/upload_dataset.py "$(FILE)" --weaviate-url "http://localhost:$$NODE_PORT" $(if $(CLASS),--class-name "$(CLASS)")

check-dataset-nodes:
	@echo "Checking which nodes are accessible for dataset upload..."
	@python3 scripts/upload_dataset.py dummy.json --check-cluster || true

# Sample dataset upload (using the jeopardy dataset if available)
upload-sample:
	@if [ -f "../datasets/jeopardy_tiny.json" ]; then \
		echo "Uploading sample jeopardy dataset..."; \
		python3 scripts/upload_dataset.py "../datasets/jeopardy_tiny.json" --class-name "Jeopardy"; \
	else \
		echo "Sample dataset not found at ../datasets/jeopardy_tiny.json"; \
		echo "Using local sample dataset instead..."; \
		python3 scripts/upload_dataset.py "datasets/sample_dataset.json" --class-name "Articles"; \
	fi

# Setup environment
setup:
	@echo "Setting up Weaviate local development environment..."
	@./scripts/setup.sh

# Install Python dependencies only
install-deps:
	@echo "Installing Python dependencies..."
	@pip3 install -r scripts/requirements.txt --user
	@echo "Dependencies installed"

# Help target
help:
	@echo "Available commands:"
	@echo ""
	@echo "Mode Selection:"
	@echo "  make up               - Start in single node mode (default)"
	@echo "  make up-single        - Start in single node mode explicitly"
	@echo "  make up-cluster       - Start in cluster mode (3 nodes)"
	@echo ""
	@echo "Stop Services:"
	@echo "  make down             - Stop all services (both modes)"
	@echo "  make down-single      - Stop single node services"
	@echo "  make down-cluster     - Stop cluster services"
	@echo ""
	@echo "Restart Services:"
	@echo "  make restart          - Restart current mode"
	@echo "  make restart-single   - Restart single node mode"
	@echo "  make restart-cluster  - Restart cluster mode"
	@echo ""
	@echo "Status & Monitoring:"
	@echo "  make status           - Show status of all services"
	@echo "  make status-single    - Show single node status"
	@echo "  make status-cluster   - Show cluster status"
	@echo "  make check-cluster    - Check cluster health (cluster mode only)"
	@echo ""
	@echo "Logs:"
	@echo "  make logs             - Show logs for all services"
	@echo "  make logs-weaviate    - Show Weaviate logs"
	@echo "  make logs-weaviate-cluster - Show all cluster node logs"
	@echo "  make logs-ollama      - Show Ollama logs"
	@echo "  make logs-init        - Show ollama-init logs"
	@echo ""
	@echo "Dataset Upload:"
	@echo "  make upload-dataset FILE=path/to/data.json           - Upload dataset to single node"
	@echo "  make upload-dataset FILE=data.json CLASS=MyClass     - Upload with custom class name"
	@echo "  make upload-dataset FILE=data.json URL=http://...    - Upload to specific URL"
	@echo "  make upload-to-cluster FILE=data.json               - Upload to cluster node 1"
	@echo "  make upload-to-cluster FILE=data.json NODE=2         - Upload to cluster node 2"
	@echo "  make upload-to-cluster FILE=data.json CLASS=MyClass  - Upload to cluster with custom class"
	@echo "  make upload-sample                                   - Upload sample jeopardy dataset"
	@echo "  make check-dataset-nodes                             - Check which nodes are accessible"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean            - Clean up all containers and volumes"
	@echo "  make clean-single     - Clean up single node setup"
	@echo "  make clean-cluster    - Clean up cluster setup"
	@echo ""
	@echo "Utilities:"
	@echo "  make check-models     - Check available models in Ollama"
	@echo "  make setup            - Setup development environment (install deps, make scripts executable)"
	@echo "  make install-deps     - Install Python dependencies only"
	@echo "  make help             - Show this help message"
	@echo ""
	@echo "Access URLs:"
	@echo "  Single Node Mode:"
	@echo "    Weaviate: http://localhost:8080"
	@echo "    Ollama: http://localhost:11435"
	@echo ""
	@echo "  Cluster Mode:"
	@echo "    Weaviate Node 1: http://localhost:8080"
	@echo "    Weaviate Node 2: http://localhost:8081" 
	@echo "    Weaviate Node 3: http://localhost:8082"
	@echo "    Ollama: http://localhost:11435"
	@echo ""
	@echo "Dataset Upload Examples:"
	@echo "  make upload-dataset FILE=datasets/sample_dataset.json"
	@echo "  make upload-to-cluster FILE=my_data.json CLASS=ProductCatalog NODE=2"
	@echo "  python3 scripts/upload_dataset.py data.json --batch-size 50 --weaviate-url http://localhost:8081"
