# Neo4J Local Development Environment

A local development setup for Neo4J graph database, supporting both single-node and cluster deployments using Docker Compose.

## Quick Start

```bash
# First-time setup
make setup

# Start Neo4J (single node)
make up

# Or start cluster mode (3 nodes)
make up-cluster
```

## Features

- **Single-node and cluster modes**
- **Docker containerization**
- **Automated setup scripts**
- **Development utilities**


## Project Structure

```
Neo4J/
├── docker/                  # Docker Compose files
├── scripts/                 # Automation and test scripts
│   ├── setup.sh             # Environment setup
│   ├── test-connection.sh   # Test Neo4J connection
│   └── test-basic-graph.sh  # Create/query sample data
├── Makefile                 # Build automation
└── README.md                # This file
```

## Sample Test Scripts

You can use the following scripts in the `scripts/` directory to test your Neo4J setup:

- `test-connection.sh`: Verifies connection and basic query
- `test-basic-graph.sh`: Creates a sample graph and queries it

Both scripts require `cypher-shell` (part of Neo4J CLI tools). You can run them after starting Neo4J:

```bash
cd scripts
./test-connection.sh
./test-basic-graph.sh
```

## Requirements

- Docker and Docker Compose
- Make (for automation commands)
- 4GB+ RAM (recommended for cluster mode)

---

For detailed documentation and advanced configuration, see the `docker/` and `scripts/` directories.
