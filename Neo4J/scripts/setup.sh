#!/bin/bash

# Setup script for Neo4J local development environment
# Installs any required dependencies (if needed)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is required but not installed."
    echo "Please install Docker and try again."
    exit 1
fi

echo "✅ Docker found: $(docker --version)"

# Check if Docker Compose is available
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is required but not installed."
    echo "Please install Docker Compose and try again."
    exit 1
fi

echo "✅ Docker Compose found: $(docker-compose --version)"

echo "Neo4J local development environment setup complete."
