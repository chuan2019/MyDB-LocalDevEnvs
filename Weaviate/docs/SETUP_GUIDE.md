# Weaviate Local Development Setup

This setup provides both single node and cluster mode deployments for Weaviate local development.

## Quick Start

### Single Node Mode (Default)
```bash
make up
# or explicitly
make up-single
```

### Cluster Mode (3 nodes)
```bash
make up-cluster
```

## Available Modes

### Single Node Mode
- **Container**: `weaviate-single`
- **Ports**: 
  - Weaviate: `8080`
  - Weaviate gRPC: `50051`
  - Ollama: `11435`
- **Use case**: Simple development, testing, prototyping

### Cluster Mode
- **Containers**: `weaviate-node1`, `weaviate-node2`, `weaviate-node3`
- **Ports**:
  - Node 1: `8080` (HTTP), `50051` (gRPC)
  - Node 2: `8081` (HTTP), `50052` (gRPC)  
  - Node 3: `8082` (HTTP), `50053` (gRPC)
  - Ollama: `11435`
- **Use case**: Testing clustering features, distributed scenarios, high availability testing

## Common Commands

### Starting Services
```bash
make up              # Start single node (default)
make up-single       # Start single node explicitly  
make up-cluster      # Start cluster mode
```

### Stopping Services
```bash
make down            # Stop all services
make down-single     # Stop single node services
make down-cluster    # Stop cluster services
```

### Monitoring
```bash
make status          # Show all service status
make status-single   # Show single node status
make status-cluster  # Show cluster status
make check-cluster   # Check cluster health (cluster mode only)
```

### Logs
```bash
make logs                    # Show all logs
make logs-weaviate          # Show Weaviate logs
make logs-weaviate-cluster  # Show all cluster node logs
make logs-ollama            # Show Ollama logs
```

### Cleanup
```bash
make clean           # Clean all containers and volumes
make clean-single    # Clean single node setup
make clean-cluster   # Clean cluster setup
```

### Dataset Upload
```bash
# Upload datasets to single node
make upload-dataset FILE=/path/to/dataset.json
make upload-dataset FILE=sample_dataset.json CLASS=Articles

# Upload datasets to cluster
make upload-to-cluster FILE=/path/to/dataset.json
make upload-to-cluster FILE=data.json NODE=2 CLASS=Products

# Upload sample dataset (if available)
make upload-sample

# Check which nodes are accessible
make check-dataset-nodes

# Direct Python script usage
python3 upload_dataset.py dataset.json --weaviate-url http://localhost:8081
python3 upload_dataset.py dataset.json --batch-size 50 --class-name MyData
```

## Dataset Upload

The setup includes a Python script for uploading JSON datasets to Weaviate with automatic schema inference.

### Features
- **Automatic schema creation** from JSON structure
- **Batch uploading** for large datasets
- **Multi-node support** for cluster deployments
- **Type inference** for Weaviate properties
- **Progress tracking** and error handling

### Supported Data Formats
- JSON files containing arrays of objects
- JSON files containing single objects (converted to array)
- Automatic property type detection (text, int, number, boolean, arrays)

### Upload Examples

#### Basic Upload
```bash
# Upload to single node (default)
make upload-dataset FILE=my_data.json

# Upload with custom class name
make upload-dataset FILE=my_data.json CLASS=ProductCatalog
```

#### Cluster Upload
```bash
# Upload to cluster node 1 (default)
make upload-to-cluster FILE=my_data.json

# Upload to specific cluster node
make upload-to-cluster FILE=my_data.json NODE=2

# Upload with custom class name to cluster
make upload-to-cluster FILE=my_data.json CLASS=Articles NODE=3
```

#### Advanced Usage
```bash
# Direct script usage with options
python3 upload_dataset.py dataset.json --batch-size 50
python3 upload_dataset.py dataset.json --weaviate-url http://localhost:8081
python3 upload_dataset.py dataset.json --no-create-schema --class-name ExistingClass
```

### Sample Dataset
A sample dataset (`sample_dataset.json`) is included for testing:
```bash
make upload-dataset FILE=sample_dataset.json CLASS=Articles
```

## Configuration Files

- `docker-compose.yml` - Main compose file (defaults to single node)
- `docker-compose.single.yml` - Single node configuration
- `docker-compose.cluster.yml` - Cluster configuration (3 nodes)

## Access URLs

### Single Node Mode
- Weaviate API: http://localhost:8080
- Ollama API: http://localhost:11435

### Cluster Mode
- Weaviate Node 1: http://localhost:8080
- Weaviate Node 2: http://localhost:8081
- Weaviate Node 3: http://localhost:8082
- Ollama API: http://localhost:11435

## Features

### Both Modes Include:
- Ollama integration with models: `nomic-embed-text`, `llama3.2`
- Automatic model downloading
- Persistent data volumes
- GPU support for Ollama (if available)
- Text2vec and generative modules enabled

### Cluster Mode Additional Features:
- 3-node Weaviate cluster
- Automatic cluster discovery
- Load balancing across nodes
- Separate data volumes per node

## Development Workflow

1. **Start with single node** for basic development:
   ```bash
   make up-single
   ```

2. **Switch to cluster mode** when testing distributed features:
   ```bash
   make down-single
   make up-cluster
   ```

3. **Check cluster health**:
   ```bash
   make check-cluster
   ```

4. **Monitor logs** during development:
   ```bash
   make logs-weaviate-cluster
   ```

## Troubleshooting

### Check what's running:
```bash
make status
```

### View logs for debugging:
```bash
make logs
```

### Clean restart:
```bash
make clean
make up
```

### Check available models:
```bash
make check-models
```

## Notes

- The cluster mode uses Weaviate's built-in clustering capabilities
- All nodes in cluster mode are configured to join the same cluster
- Data is automatically distributed across cluster nodes
- You can connect to any cluster node - requests will be distributed automatically
- GPU support requires NVIDIA Docker runtime for Ollama
