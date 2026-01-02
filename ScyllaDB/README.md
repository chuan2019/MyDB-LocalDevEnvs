# ScyllaDB Local Development Environment

A local development setup for ScyllaDB NoSQL database, supporting both single-node and cluster deployments using Docker Compose.

## Quick Start

```bash
# First-time setup
make setup

# Start ScyllaDB (single node)
make up

# Or start cluster mode (3 nodes)
make up-cluster
```

## Features

- **Single-node and cluster modes**
- **Docker containerization**
- **High-performance NoSQL database**
- **Cassandra-compatible API (CQL)**
- **DynamoDB-compatible API (Alternator)**
- **Automated setup scripts**
- **Development utilities**
- **Jupyter notebooks for learning and testing**
- **Python virtual environment with uv**

## Project Structure

```
ScyllaDB/
├── docker/                    # Docker Compose files
│   ├── docker-compose.single.yml
│   ├── docker-compose.cluster.yml
│   └── docker-compose.yml
├── notebooks/                 # Jupyter notebooks for demos
│   ├── 01-getting-started.ipynb
│   ├── 02-advanced-queries.ipynb
│   └── 03-data-modeling.ipynb
├── scripts/                   # Automation and test scripts
│   ├── setup.sh               # Environment setup
│   ├── test-connection.sh     # Test ScyllaDB connection
│   └── test-cluster.py        # Test cluster with Python
├── pyproject.toml             # Python dependencies (uv)
├── .python-version            # Python version specification
├── Makefile                   # Build automation
└── README.md                  # This file
```

## Access Points

### Single Node Mode
- **CQL Protocol**: `127.0.0.1:9042`
- **Alternator (DynamoDB API)**: `http://localhost:10000`
- **JMX**: `localhost:7199`

### Cluster Mode
- **Node 1 CQL**: `127.0.0.1:9042`
- **Node 2 CQL**: `127.0.0.1:9043`
- **Node 3 CQL**: `127.0.0.1:9044`
- **Alternator**: `http://localhost:10000` (via Node 1)

## Requirements

- Docker and Docker Compose
- Make (for automation commands)
- 8GB+ RAM (recommended for cluster mode)
- Python 3.8+ (for notebooks and test scripts)
- uv (recommended) or pip for Python package management

### Installing uv (Recommended)

uv is a fast Python package installer and resolver:

```bash
# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Or with pip
pip install uv
```

## Common Commands

```bash
# Setup and Python environment
make setup           # Run setup script and create venv with uv
source .venv/bin/activate  # Activate virtual environment

# Start services
make up              # Start single node
make up-cluster      # Start cluster (3 nodes)

# Stop services
make down            # Stop single node
make down-cluster    # Stop cluster

# Check status
make status          # Single node status
make status-cluster  # Cluster status

# View logs
make logs            # View single node logs
make logs-cluster    # View cluster logs

# Notebooks
make notebook        # Start Jupyter Lab with notebooks

# Clean up
make clean           # Remove all containers and volumes
```

## Working with Jupyter Notebooks

This project includes interactive Jupyter notebooks for learning and testing ScyllaDB:

### Setup Virtual Environment

```bash
# Run setup (includes uv venv creation and dependency installation)
make setup

# Activate the virtual environment
source .venv/bin/activate
```

### Start Jupyter Lab

```bash
# Make sure ScyllaDB is running
make up

# Start Jupyter Lab
make notebook

# Or manually:
jupyter lab notebooks/
```

### Available Notebooks

1. **01-getting-started.ipynb**
   - Basic connection to ScyllaDB
   - Creating keyspaces and tables
   - CRUD operations (Create, Read, Update, Delete)
   - Prepared statements

2. **02-advanced-queries.ipynb**
   - Time series data patterns
   - Secondary indexes
   - Batch operations
   - Query performance optimization
   - ALLOW FILTERING

3. **03-data-modeling.ipynb**
   - Query-first design approach
   - Partition key selection
   - Data denormalization patterns
   - Collections (lists, sets, maps)
   - Counter columns
   - Best practices and anti-patterns
make logs            # View single node logs
make logs-cluster    # View cluster logs

# Clean up
make clean           # Remove all containers and volumes
```

## Sample Test Scripts

You can use the following scripts in the `scripts/` directory to test your ScyllaDB setup:

- `test-connection.sh`: Verifies connection and basic CQL query
- `test-cluster.py`: Creates a keyspace, inserts data, and queries it

Run them after starting ScyllaDB:

```bash
cd scripts
./test-connection.sh

# For Python test (requires cassandra-driver)
pip install cassandra-driver
python test-cluster.py
```

## Query Language

ScyllaDB uses CQL (Cassandra Query Language). Example queries:

```cql
-- Create a keyspace
CREATE KEYSPACE IF NOT EXISTS demo 
WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 3};

-- Use the keyspace
USE demo;

-- Create a table
CREATE TABLE users (
    user_id UUID PRIMARY KEY,
    username text,
    email text,
    created_at timestamp
);

-- Insert data
INSERT INTO users (user_id, username, email, created_at) 
VALUES (uuid(), 'john_doe', 'john@example.com', toTimestamp(now()));

-- Query data
SELECT * FROM users WHERE user_id = <uuid>;
```

## Performance Configuration

The docker-compose configurations are set for development with:
- `--smp 2`: 2 CPU cores per node
- `--memory 2G`: 2GB RAM per node

For production-like testing, you can adjust these values in the docker-compose files.

## Cluster Formation

When starting a cluster, ScyllaDB nodes need time to discover each other and form the ring. Wait 1-2 minutes after starting before running queries. You can check cluster status with:

```bash
# Check node status in any container
docker exec scylla-node1 nodetool status
```

## Troubleshooting

### Cluster not forming
- Ensure sufficient RAM (at least 8GB total)
- Wait 1-2 minutes for nodes to discover each other
- Check logs: `make logs-cluster`

### Connection refused
- ScyllaDB can take 30-60 seconds to start
- Verify containers are running: `make status` or `make status-cluster`
- Check if ports are already in use

### Performance issues
- Increase memory allocation in docker-compose files
- Reduce number of nodes for development
- Ensure Docker has sufficient resources allocated

## Additional Resources

- [ScyllaDB Documentation](https://docs.scylladb.com/)
- [CQL Reference](https://docs.scylladb.com/stable/cql/index.html)
- [ScyllaDB University](https://university.scylladb.com/)
- [Cassandra Driver for Python](https://docs.datastax.com/en/developer/python-driver/)

---

For detailed documentation and advanced configuration, see the `docker/` and `scripts/` directories.
