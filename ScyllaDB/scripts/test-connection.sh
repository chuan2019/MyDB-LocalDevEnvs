#!/bin/bash

# Test ScyllaDB connection script
# This script verifies that ScyllaDB is running and can execute basic CQL queries

set -e

SCYLLA_HOST="${SCYLLA_HOST:-127.0.0.1}"
SCYLLA_PORT="${SCYLLA_PORT:-9042}"

echo "Testing ScyllaDB connection at ${SCYLLA_HOST}:${SCYLLA_PORT}..."
echo

# Check if cqlsh is available
if ! command -v cqlsh &> /dev/null; then
    echo "Warning: cqlsh not found. Install it with: pip install cqlsh"
    echo "Alternatively, you can run cqlsh from within the container:"
    echo "  docker exec -it scylla-single cqlsh"
    echo
    exit 1
fi

# Test connection with a simple query
echo "Attempting to connect and query system tables..."
if cqlsh ${SCYLLA_HOST} ${SCYLLA_PORT} -e "SELECT cluster_name FROM system.local;" 2>/dev/null; then
    echo
    echo "[OK] Connection successful!"
    echo
    echo "You can now connect with:"
    echo "  cqlsh ${SCYLLA_HOST} ${SCYLLA_PORT}"
    echo
    echo "Or from within the container:"
    echo "  docker exec -it scylla-single cqlsh"
else
    echo
    echo "[FAILED] Connection failed. ScyllaDB might still be starting up."
    echo "  Wait 30-60 seconds and try again."
    echo
    exit 1
fi
