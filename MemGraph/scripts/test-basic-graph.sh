#!/bin/bash
# test-basic-graph.sh
# Script to create a sample graph in MemGraph and query it

set -e

MEMGRAPH_URI="bolt://localhost:7687"

echo "Creating a sample graph in MemGraph..."

# Create sample nodes and relationships
docker run --rm \
  --network=memgraph-single_memgraph_net \
  memgraph/memgraph-platform:latest \
  mgconsole --host memgraph-single --port 7687 --use-ssl=False \
  --query "
    // Clear existing data
    MATCH (n) DETACH DELETE n;
    
    // Create sample nodes
    CREATE (alice:Person {name: 'Alice', age: 30, city: 'New York'})
    CREATE (bob:Person {name: 'Bob', age: 35, city: 'San Francisco'})
    CREATE (charlie:Person {name: 'Charlie', age: 28, city: 'New York'})
    CREATE (project1:Project {name: 'GraphDB Research', status: 'Active'})
    CREATE (project2:Project {name: 'Data Analysis', status: 'Completed'})
    
    // Create relationships
    CREATE (alice)-[:WORKS_WITH {since: 2020}]->(bob)
    CREATE (bob)-[:WORKS_WITH {since: 2019}]->(charlie)
    CREATE (alice)-[:CONTRIBUTES_TO {role: 'Lead'}]->(project1)
    CREATE (bob)-[:CONTRIBUTES_TO {role: 'Developer'}]->(project1)
    CREATE (charlie)-[:CONTRIBUTES_TO {role: 'Analyst'}]->(project2)
    CREATE (alice)-[:FRIENDS_WITH]->(charlie)
    
    RETURN 'Sample graph created successfully!' AS message;
  "

echo ""
echo "Querying the sample graph..."

# Query 1: Get all people and their projects
echo "Query 1: People and their projects"
docker run --rm \
  --network=memgraph-single_memgraph_net \
  memgraph/memgraph-platform:latest \
  mgconsole --host memgraph-single --port 7687 --use-ssl=False \
  --query "
    MATCH (p:Person)-[r:CONTRIBUTES_TO]->(proj:Project)
    RETURN p.name AS person, r.role AS role, proj.name AS project
    ORDER BY person;
  "

echo ""
echo "Query 2: Find colleagues (people working on same projects)"
docker run --rm \
  --network=memgraph-single_memgraph_net \
  memgraph/memgraph-platform:latest \
  mgconsole --host memgraph-single --port 7687 --use-ssl=False \
  --query "
    MATCH (p1:Person)-[:CONTRIBUTES_TO]->(proj:Project)<-[:CONTRIBUTES_TO]-(p2:Person)
    WHERE p1.name < p2.name
    RETURN p1.name AS person1, p2.name AS person2, proj.name AS shared_project;
  "

echo ""
echo "Query 3: Graph statistics"
docker run --rm \
  --network=memgraph-single_memgraph_net \
  memgraph/memgraph-platform:latest \
  mgconsole --host memgraph-single --port 7687 --use-ssl=False \
  --query "
    MATCH (n)
    WITH count(n) AS node_count
    MATCH ()-[r]->()
    RETURN node_count AS total_nodes, count(r) AS total_relationships;
  "

echo ""
echo "✅ Sample graph tests completed successfully!"
echo "You can now explore the graph using MemGraph Lab at http://localhost:3000"
