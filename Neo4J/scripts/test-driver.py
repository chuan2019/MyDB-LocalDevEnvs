import sys
import time
from neo4j import GraphDatabase, basic_auth

uri = "bolt://localhost:7687"
user = "neo4j"
password = "testpass"

# Wait for Neo4J to be ready (retry for up to 30 seconds)
for i in range(30):
    try:
        driver = GraphDatabase.driver(uri, auth=basic_auth(user, password))
        with driver.session() as session:
            result = session.run("RETURN 1 AS test")
            print("Cypher result:", result.single()["test"])
        print("✅ Python driver connection and query successful.")
        sys.exit(0)
    except Exception as e:
        print(f"Attempt {i+1}: {e}")
        time.sleep(1)

print("❌ Could not connect to Neo4J with Python driver after 30 seconds.")
sys.exit(1)
