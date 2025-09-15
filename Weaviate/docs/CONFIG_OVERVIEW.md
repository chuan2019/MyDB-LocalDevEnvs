# Weaviate Local Development Configuration Overview

## File Structure
```
local-dev/
├── docker-compose.yml              # Main compose file (points to single mode)
├── docker-compose.single.yml       # Single node configuration
├── docker-compose.cluster.yml      # Cluster configuration (3 nodes)
├── Makefile                        # Build automation with mode support
├── switch-mode.sh                  # Interactive mode switcher script
├── upload_dataset.py               # Dataset upload script
├── setup.sh                        # Environment setup script
├── requirements.txt                # Python dependencies
├── sample_dataset.json             # Sample dataset for testing
├── README.md                       # Comprehensive documentation
├── DATASET_UPLOAD_GUIDE.md         # Dataset upload specific guide
├── CONFIG_OVERVIEW.md              # This file
└── models/                         # Ollama models directory
```

## Configuration Differences

### Single Node Mode (`docker-compose.single.yml`)
```yaml
services:
  weaviate:                    # Single container
    container_name: weaviate-single
    ports: [8080:8080, 50051:50051]
    environment:
      CLUSTER_HOSTNAME: 'node1'
```

### Cluster Mode (`docker-compose.cluster.yml`)
```yaml
services:
  weaviate-node1:              # First node
    ports: [8080:8080, 50051:50051]
    environment:
      CLUSTER_HOSTNAME: 'node1'
      CLUSTER_JOIN: 'node1:7946,node2:7946,node3:7946'
  
  weaviate-node2:              # Second node
    ports: [8081:8080, 50052:50051]
    environment:
      CLUSTER_HOSTNAME: 'node2'
      CLUSTER_JOIN: 'node1:7946,node2:7946,node3:7946'
  
  weaviate-node3:              # Third node
    ports: [8082:8080, 50053:50051]
    environment:
      CLUSTER_HOSTNAME: 'node3'
      CLUSTER_JOIN: 'node1:7946,node2:7946,node3:7946'
```

## Port Mappings

### Single Node Mode
- **Weaviate HTTP**: `localhost:8080`
- **Weaviate gRPC**: `localhost:50051`
- **Ollama**: `localhost:11435`

### Cluster Mode
- **Node 1 HTTP**: `localhost:8080`
- **Node 1 gRPC**: `localhost:50051`
- **Node 2 HTTP**: `localhost:8081`
- **Node 2 gRPC**: `localhost:50052`
- **Node 3 HTTP**: `localhost:8082`
- **Node 3 gRPC**: `localhost:50053`
- **Ollama**: `localhost:11435`

## Volume Mappings

### Single Node Mode
```yaml
volumes:
  weaviate_data: {}              # Single data volume
  ollama_data: {}                # Shared Ollama data
```

### Cluster Mode
```yaml
volumes:
  weaviate_node1_data: {}        # Separate data per node
  weaviate_node2_data: {}
  weaviate_node3_data: {}
  ollama_data: {}                # Shared Ollama data
```

## Environment Variables

### Common to Both Modes
```yaml
QUERY_DEFAULTS_LIMIT: 25
AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED: 'true'
PERSISTENCE_DATA_PATH: '/var/lib/weaviate'
ENABLE_API_BASED_MODULES: 'true'
ENABLE_MODULES: 'text2vec-ollama,generative-ollama'
```

### Cluster Mode Additional
```yaml
CLUSTER_GOSSIP_BIND_PORT: '7946'    # Cluster communication
CLUSTER_DATA_BIND_PORT: '7947'      # Data replication
CLUSTER_JOIN: 'node1:7946,node2:7946,node3:7946'  # Cluster discovery
```

## Usage Patterns

### Development Workflow
1. **Start simple**: `make up` (single node)
2. **Test clustering**: `make up-cluster`
3. **Switch modes**: `./switch-mode.sh cluster`
4. **Monitor**: `make status`, `make logs`
5. **Clean up**: `make clean`

### Common Commands by Use Case

#### Quick Development
```bash
make up              # Start quickly in single mode
make logs-weaviate   # Monitor development
make down            # Stop when done
```

#### Cluster Testing
```bash
make up-cluster      # Start cluster
make check-cluster   # Verify cluster health
make logs-weaviate-cluster  # Monitor all nodes
make clean-cluster   # Clean up cluster data
```

#### Debugging
```bash
make status          # See what's running
make logs            # View all logs
./switch-mode.sh status  # Interactive status check
```

## Notes
- Both modes share the same Ollama instance and models
- Cluster mode provides automatic load balancing
- Data persistence is maintained separately for each mode
- GPU support is configured for Ollama when available
- All configurations use the same Weaviate version for consistency

## Dataset Upload Configuration

### Upload Script Features
- **Language**: Python 3 with requests library
- **Schema inference**: Automatic Weaviate schema creation from JSON structure
- **Batch processing**: Configurable batch sizes (default: 100 objects)
- **Multi-node support**: Can target any cluster node
- **Error handling**: Comprehensive error reporting and recovery
- **Progress tracking**: Real-time upload progress display

### Supported Formats
```json
// Array of objects (recommended)
[
  {"field1": "value1", "field2": 123},
  {"field1": "value2", "field2": 456}
]

// Single object (auto-converted to array)
{"field1": "value1", "field2": 123}
```

### Type Mapping
```yaml
JSON Type → Weaviate Type:
  string → text
  integer → int
  float → number
  boolean → boolean
  array of strings → text[]
  mixed array → text[]
```

### Integration Points
```yaml
Makefile Targets:
  upload-dataset: Single node upload
  upload-to-cluster: Cluster node upload
  upload-sample: Sample data upload
  check-dataset-nodes: Node accessibility check
  setup: Environment setup
  install-deps: Python dependencies only

Python Script Options:
  --class-name: Custom Weaviate class name
  --weaviate-url: Target Weaviate instance
  --batch-size: Upload batch size
  --no-create-schema: Skip automatic schema creation
  --check-cluster: Check all cluster nodes
```
