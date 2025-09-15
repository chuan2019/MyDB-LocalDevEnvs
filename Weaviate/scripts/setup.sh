#!/bin/bash

# Setup script for Weaviate local development environment
# This script installs required Python dependencies for dataset upload

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🔧 Setting up Weaviate local development environment..."

# Check if Python 3 is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is required but not installed"
    echo "Please install Python 3 and try again"
    exit 1
fi

echo "✅ Python 3 found: $(python3 --version)"

# Check if pip is available
if ! command -v pip3 &> /dev/null; then
    echo "❌ pip3 is required but not installed"
    echo "Please install pip3 and try again"
    exit 1
fi

echo "✅ pip3 found"

# Install Python dependencies
echo "📦 Installing Python dependencies..."
pip3 install -r requirements.txt --user

echo "✅ Python dependencies installed"

# Check if docker and docker-compose are available
if ! command -v docker &> /dev/null; then
    echo "⚠️  Docker is not installed - you'll need it to run Weaviate"
    echo "Please install Docker and try again"
    exit 1
fi

echo "✅ Docker found: $(docker --version)"

if ! command -v docker-compose &> /dev/null; then
    echo "⚠️  docker-compose is not installed - you'll need it to run Weaviate"
    echo "Please install docker-compose and try again"
    exit 1
fi

echo "✅ docker-compose found: $(docker-compose --version)"

# Make scripts executable
chmod +x upload_dataset.py
chmod +x switch-mode.sh

echo "✅ Scripts made executable"

echo ""
echo "🎉 Setup completed successfully!"
echo ""
echo "📋 Next steps:"
echo "  1. Start Weaviate: make up"
echo "  2. Upload sample data: make upload-dataset FILE=datasets/sample_dataset.json"
echo "  3. View help: make help"
echo ""
echo "🔗 After starting, access Weaviate at: http://localhost:8080"
