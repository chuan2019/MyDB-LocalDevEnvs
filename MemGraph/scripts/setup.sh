#!/bin/bash

# Setup script for MemGraph local development environment
# Installs any required dependencies (if needed)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "==================================="
echo "MemGraph Environment Setup"
echo "==================================="

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

# Check Docker daemon is running
if ! docker info &> /dev/null; then
    echo "❌ Docker daemon is not running."
    echo "Please start Docker and try again."
    exit 1
fi

echo "✅ Docker daemon is running"

# Create necessary directories if they don't exist
cd ..
mkdir -p docker scripts

echo ""
echo "==================================="
echo "✅ Setup Complete!"
echo "==================================="
echo ""
echo "Next steps:"
echo "  1. Start MemGraph: make up"
echo "  2. Access MemGraph Lab: http://localhost:3000"
echo "  3. Test connection: cd scripts && ./test-connection.sh"
echo ""
