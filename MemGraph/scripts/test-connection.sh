#!/bin/bash
# test-connection.sh
# Simple script to test MemGraph connection and basic Cypher query

set -e

MEMGRAPH_URI="bolt://localhost:7687"

echo "Testing connection to MemGraph at $MEMGRAPH_URI ..."

# Use Docker to run mgconsole (MemGraph console client)
docker run --rm \
  --network=memgraph-single_memgraph_net \
  memgraph/memgraph-platform:latest \
  mgconsole --host memgraph-single --port 7687 --use-ssl=False \
  --query "RETURN 'Connection successful!' AS message, 42 AS answer;"

if [ $? -eq 0 ]; then
    echo "✅ Connection successful and query executed."
else
    echo "❌ Connection or query failed."
    exit 1
fi
