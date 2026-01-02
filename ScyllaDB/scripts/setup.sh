#!/bin/bash

# ScyllaDB Local Development Environment Setup Script
# This script checks for required dependencies and sets up the environment

set -e

echo "=================================================="
echo "ScyllaDB Local Development Environment Setup"
echo "=================================================="
echo

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Print colored status messages
print_status() {
    if [ "$1" = "ok" ]; then
        echo -e "${GREEN}[OK]${NC} $2"
    elif [ "$1" = "warning" ]; then
        echo -e "${YELLOW}[WARNING]${NC} $2"
    elif [ "$1" = "error" ]; then
        echo -e "${RED}[FAILED]${NC} $2"
    else
        echo "$2"
    fi
}

# Check Docker
echo "Checking required dependencies..."
echo

if command_exists docker; then
    DOCKER_VERSION=$(docker --version | cut -d ' ' -f3 | cut -d ',' -f1)
    print_status "ok" "Docker found (version $DOCKER_VERSION)"
else
    print_status "error" "Docker not found"
    echo "  Please install Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check Docker Compose
if command_exists docker-compose || docker compose version >/dev/null 2>&1; then
    if command_exists docker-compose; then
        COMPOSE_VERSION=$(docker-compose --version | cut -d ' ' -f3 | cut -d ',' -f1)
    else
        COMPOSE_VERSION=$(docker compose version --short)
    fi
    print_status "ok" "Docker Compose found (version $COMPOSE_VERSION)"
else
    print_status "error" "Docker Compose not found"
    echo "  Please install Docker Compose: https://docs.docker.com/compose/install/"
    exit 1
fi

# Check Docker daemon
if docker info >/dev/null 2>&1; then
    print_status "ok" "Docker daemon is running"
else
    print_status "error" "Docker daemon is not running"
    echo "  Please start Docker daemon"
    exit 1
fi

# Check Make
if command_exists make; then
    print_status "ok" "Make found"
else
    print_status "warning" "Make not found (optional, but recommended)"
    echo "  Install with: sudo apt-get install make (Debian/Ubuntu)"
    echo "              sudo yum install make (CentOS/RHEL)"
fi

echo

# Check optional Python dependencies
echo "Checking optional dependencies..."
echo

# Check for uv (recommended Python package manager)
if command_exists uv; then
    UV_VERSION=$(uv --version | cut -d ' ' -f2)
    print_status "ok" "uv found (version $UV_VERSION)"
else
    print_status "warning" "uv not found (recommended for Python environment management)"
    echo "  Install with: curl -LsSf https://astral.sh/uv/install.sh | sh"
    echo "  Or: pip install uv"
fi

if command_exists python3; then
    PYTHON_VERSION=$(python3 --version | cut -d ' ' -f2)
    print_status "ok" "Python 3 found (version $PYTHON_VERSION)"
    
    # Check for cassandra-driver
    if python3 -c "import cassandra" 2>/dev/null; then
        print_status "ok" "cassandra-driver Python package found"
    else
        print_status "warning" "cassandra-driver Python package not found (optional)"
        echo "  Install with: uv pip install cassandra-driver"
        echo "  Or: pip install cassandra-driver"
        echo "  Required for Python test scripts and notebooks"
    fi
    
    # Check for jupyter
    if python3 -c "import jupyter" 2>/dev/null; then
        print_status "ok" "Jupyter found"
    else
        print_status "warning" "Jupyter not found (optional)"
        echo "  Install with: uv pip install jupyter"
        echo "  Or: pip install jupyter"
        echo "  Required for running notebooks"
    fi
else
    print_status "warning" "Python 3 not found (optional)"
    echo "  Required for Python test scripts and notebooks"
fi

# Check for cqlsh
if command_exists cqlsh; then
    print_status "ok" "cqlsh found"
else
    print_status "warning" "cqlsh not found (optional)"
    echo "  Install with: pip install cqlsh"
    echo "  Required for CQL shell scripts"
    echo "  Alternatively, use cqlsh from within containers"
fi

echo
echo "=================================================="
echo "Setup Check Complete"
echo "=================================================="
echo

# Make scripts executable
echo "Making scripts executable..."
chmod +x test-connection.sh 2>/dev/null || true
chmod +x test-cluster.py 2>/dev/null || true
print_status "ok" "Scripts are now executable"

# Setup Python virtual environment with uv if available
echo
if command_exists uv; then
    echo "Setting up Python virtual environment with uv..."
    cd "$(dirname "$0")/.." || exit
    
    if [ ! -d ".venv" ]; then
        print_status "info" "Creating virtual environment..."
        uv venv
        print_status "ok" "Virtual environment created"
        
        print_status "info" "Installing dependencies..."
        uv pip install -e .
        print_status "ok" "Dependencies installed"
    else
        print_status "ok" "Virtual environment already exists"
        print_status "info" "To update dependencies, run: uv pip install -e ."
    fi
    
    echo
    echo "To activate the virtual environment:"
    echo "  source .venv/bin/activate"
else
    echo "uv not found - skipping virtual environment setup"
    echo "Install uv and run this script again for automatic setup"
fi

echo
echo "Next steps:"
echo "  1. Activate virtual environment: source .venv/bin/activate"
echo "  2. Start ScyllaDB single node:  make up"
echo "  3. Start ScyllaDB cluster:      make up-cluster"
echo "  4. Run Jupyter notebooks:       make notebook"
echo "  5. Check status:                make status"
echo "  6. View all commands:           make help"
echo
echo "For more information, see README.md"
echo
