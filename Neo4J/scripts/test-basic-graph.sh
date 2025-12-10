#!/bin/bash
# test-basic-graph.sh
# Script to create a sample node and relationship, then query it

set -e

NEO4J_URI="bolt://localhost:7687"
NEO4J_USER="neo4j"
NEO4J_PASS="testpass"

echo "Creating sample data in Neo4J..."
# Use Docker to run cypher-shell
echo "Creating sample data in Neo4J..."

docker run --rm \
  --network=neo4j-single_neo4j_net \
  neo4j:5.18.0 cypher-shell -a "neo4j://neo4j-single:7687" -u "$NEO4J_USER" -p "$NEO4J_PASS" "CREATE (a:Person {name: 'Alice'})-[:KNOWS]->(b:Person {name: 'Bob'});"

docker run --rm \
  --network=neo4j-single_neo4j_net \
  neo4j:5.18.0 cypher-shell -a "neo4j://neo4j-single:7687" -u "$NEO4J_USER" -p "$NEO4J_PASS" "MATCH (a:Person)-[r:KNOWS]->(b:Person) RETURN a.name, type(r), b.name;"

if [ $? -eq 0 ]; then
    echo "✅ Sample data created and queried successfully."
else
    echo "❌ Failed to create/query sample data."
    exit 1
fi
