# MemGraph Local Development Environment

A local development setup for MemGraph in-memory graph database, supporting both single-node and cluster deployments using Docker Compose.

## Quick Start

```bash
# First-time setup
make setup

# Start MemGraph (single node)
make up

# Or start cluster mode (3 nodes)
make up-cluster
```

## Features

- **Single-node and cluster modes**
- **Docker containerization**
- **In-memory graph database with persistent storage**
- **Automated setup scripts**
- **Development utilities**

## Project Structure

```
MemGraph/
├── docker/                  # Docker Compose files
├── scripts/                 # Automation and test scripts
│   ├── setup.sh             # Environment setup
│   ├── test-connection.sh   # Test MemGraph connection
│   └── test-basic-graph.sh  # Create/query sample data
├── Makefile                 # Build automation
└── README.md                # This file
```

## Access Points

### Single Node Mode
- **Bolt Protocol**: `bolt://localhost:7687`
- **Lab UI**: http://localhost:3000
- **Username**: (no authentication by default)

### Cluster Mode
- **Node 1 Bolt**: `bolt://localhost:7687`
- **Node 1 Lab**: http://localhost:3000
- **Node 2 Bolt**: `bolt://localhost:7688`
- **Node 2 Lab**: http://localhost:3001
- **Node 3 Bolt**: `bolt://localhost:7689`
- **Node 3 Lab**: http://localhost:3002

## Sample Test Scripts

You can use the following scripts in the `scripts/` directory to test your MemGraph setup:

- `test-connection.sh`: Verifies connection and basic query
- `test-basic-graph.sh`: Creates a sample graph and queries it

Run them after starting MemGraph:

```bash
cd scripts
./test-connection.sh
./test-basic-graph.sh
```

## Requirements

- Docker and Docker Compose
- Make (for automation commands)
- 4GB+ RAM (recommended for cluster mode)

## Common Commands

```bash
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

# Clean up
make clean           # Remove all containers and volumes
```

## Query Language

MemGraph uses openCypher query language (compatible with Neo4j Cypher). Example queries:

```cypher
// Create nodes
CREATE (p:Person {name: 'Alice', age: 30});

// Create relationships
MATCH (a:Person {name: 'Alice'})
CREATE (a)-[:FRIENDS_WITH]->(b:Person {name: 'Bob'});

// Query graph
MATCH (p:Person)-[:FRIENDS_WITH]->(friend)
RETURN p.name, friend.name;
```

## Data Persistence

Data is persisted in Docker volumes:
- Single node: `memgraph_data`
- Cluster: `memgraph_data1`, `memgraph_data2`, `memgraph_data3`

To completely reset the database, use `make clean`.

---

For detailed documentation, visit: https://memgraph.com/docs
