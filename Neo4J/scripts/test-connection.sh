#!/bin/bash
# test-connection.sh
# Simple script to test Neo4J connection and basic Cypher query

set -e

NEO4J_URI="bolt://localhost:7687"
NEO4J_USER="neo4j"
NEO4J_PASS="testpass"

echo "Testing connection to Neo4J at $NEO4J_URI ..."
# Use Docker to run cypher-shell
echo "Testing connection to Neo4J at $NEO4J_URI ..."

docker run --rm \
  --network=neo4j-single_neo4j_net \
  neo4j:5.18.0 cypher-shell -a "neo4j://neo4j-single:7687" -u "$NEO4J_USER" -p "$NEO4J_PASS" "RETURN 1 AS test;"

if [ $? -eq 0 ]; then
    echo "✅ Connection successful and query executed."
else
    echo "❌ Connection or query failed."
    exit 1
fi
