# Weaviate Local Development Environment

A comprehensive local development setup for Weaviate vector database with support for both single-node and cluster deployments.

## Quick Start

```bash
# First-time setup
make setup

# Start Weaviate (single node)
make up

# Or start cluster mode (3 nodes)
make up-cluster

# Upload sample dataset
make upload-sample
```

## Features

- **Single-node and cluster modes** - Flexible deployment options
- **Docker containerization** - Isolated development environment
- **Automated setup scripts** - One-command installation
- **Dataset upload tools** - Easy data ingestion
- **Development utilities** - Debugging and monitoring tools

## Project Structure

```
local-dev/
├── docs/                          # Comprehensive documentation
│   ├── README.md                  # Detailed setup and usage guide
│   ├── CONFIG_OVERVIEW.md         # Configuration reference
│   └── DATASET_UPLOAD_GUIDE.md    # Dataset management guide
├── docker/                        # Docker configurations
├── datasets/                      # Sample datasets
├── scripts/                       # Automation scripts
├── models/                        # Ollama models directory
├── Makefile                       # Build automation
└── docker-compose.yml             # Main compose file
```

## Comprehensive Documentation

For detailed information, please refer to the documentation in the [`docs/`](./docs/) directory:

### Setup and Configuration
- **[Setup Guide](./docs/SETUP_GUIDE.md)** - Complete installation and configuration instructions
- **[Configuration Overview](./docs/CONFIG_OVERVIEW.md)** - Detailed configuration options and file structure

### Data Management
- **[Dataset Upload Guide](./docs/DATASET_UPLOAD_GUIDE.md)** - Upload datasets and manage data ingestion

## Common Tasks

| Task | Command | Description |
|------|---------|-------------|
| **Setup** | `make setup` | First-time environment setup |
| **Start Single Node** | `make up` | Launch single Weaviate instance |
| **Start Cluster** | `make up-cluster` | Launch 3-node Weaviate cluster |
| **Stop Services** | `make down` | Stop all running services |
| **Upload Data** | `make upload` | Upload custom dataset |
| **Health Check** | `make health` | Check service status |
| **View Logs** | `make logs` | View service logs |
| **Clean Up** | `make clean` | Remove containers and volumes |

## Quick Links

- **[Weaviate Console](http://localhost:8080)** - Database management interface (when running)
- **[API Documentation](http://localhost:8080/v1/)** - REST API reference
- **[GraphQL Playground](http://localhost:8080/v1/graphql)** - Interactive GraphQL interface

## Requirements

- Docker and Docker Compose
- Python 3.8+ (for dataset upload tools)
- Make (for automation commands)
- 4GB+ RAM (recommended for cluster mode)

---

**For detailed documentation, examples, and advanced configuration options, see the [`docs/`](./docs/) directory.**