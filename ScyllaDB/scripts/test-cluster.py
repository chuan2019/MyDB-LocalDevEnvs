#!/usr/bin/env python3
"""
Test ScyllaDB cluster connection and basic operations.

This script:
1. Connects to the ScyllaDB cluster
2. Creates a test keyspace
3. Creates a test table
4. Inserts sample data
5. Queries the data back
"""

import time
import sys
from cassandra.cluster import Cluster
from cassandra import ConsistencyLevel
from cassandra.query import SimpleStatement

# Configuration
SCYLLA_HOSTS = ["127.0.0.1"]
SCYLLA_PORT = 9042
KEYSPACE = "test_keyspace"
TABLE = "test_table"
MAX_RETRIES = 10
RETRY_DELAY = 5


def connect_with_retry():
    """Connect to ScyllaDB with retry logic."""
    last_exception = None
    
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            print(f"Attempt {attempt}/{MAX_RETRIES}: Connecting to ScyllaDB at {SCYLLA_HOSTS[0]}:{SCYLLA_PORT}...")
            cluster = Cluster(SCYLLA_HOSTS, port=SCYLLA_PORT)
            session = cluster.connect()
            print(f"✓ Connected successfully on attempt {attempt}")
            return cluster, session
        except Exception as e:
            print(f"✗ Connection failed: {e}")
            last_exception = e
            if attempt < MAX_RETRIES:
                print(f"  Retrying in {RETRY_DELAY} seconds...")
                time.sleep(RETRY_DELAY)
    
    print(f"\n✗ Failed to connect after {MAX_RETRIES} attempts")
    raise last_exception


def create_keyspace(session):
    """Create a test keyspace."""
    print(f"\nCreating keyspace '{KEYSPACE}'...")
    query = f"""
        CREATE KEYSPACE IF NOT EXISTS {KEYSPACE}
        WITH replication = {{'class': 'SimpleStrategy', 'replication_factor': 2}}
    """
    session.execute(query)
    print(f"✓ Keyspace '{KEYSPACE}' created")


def create_table(session):
    """Create a test table."""
    print(f"\nCreating table '{TABLE}'...")
    session.set_keyspace(KEYSPACE)
    query = f"""
        CREATE TABLE IF NOT EXISTS {TABLE} (
            id int PRIMARY KEY,
            name text,
            value text,
            created_at timestamp
        )
    """
    session.execute(query)
    print(f"✓ Table '{TABLE}' created")


def insert_test_data(session):
    """Insert sample data into the test table."""
    print("\nInserting test data...")
    
    test_data = [
        (1, "test1", "Hello ScyllaDB", "toTimestamp(now())"),
        (2, "test2", "High Performance", "toTimestamp(now())"),
        (3, "test3", "NoSQL Database", "toTimestamp(now())"),
    ]
    
    for id_val, name, value, _ in test_data:
        query = f"""
            INSERT INTO {TABLE} (id, name, value, created_at)
            VALUES ({id_val}, '{name}', '{value}', toTimestamp(now()))
        """
        session.execute(query)
        print(f"  ✓ Inserted row with id={id_val}")
    
    print("✓ All test data inserted")


def query_data(session):
    """Query and display the test data."""
    print("\nQuerying test data...")
    
    query = f"SELECT id, name, value, created_at FROM {TABLE}"
    statement = SimpleStatement(query, consistency_level=ConsistencyLevel.ONE)
    rows = session.execute(statement)
    
    print("\nResults:")
    print("-" * 80)
    print(f"{'ID':<5} {'Name':<10} {'Value':<20} {'Created At':<30}")
    print("-" * 80)
    
    for row in rows:
        print(f"{row.id:<5} {row.name:<10} {row.value:<20} {str(row.created_at):<30}")
    
    print("-" * 80)
    print("✓ Query completed successfully")


def cleanup(session):
    """Optional: Drop the test keyspace."""
    print("\nCleaning up (dropping test keyspace)...")
    try:
        session.execute(f"DROP KEYSPACE IF EXISTS {KEYSPACE}")
        print(f"✓ Keyspace '{KEYSPACE}' dropped")
    except Exception as e:
        print(f"Note: Cleanup skipped - {e}")


def main():
    """Main test function."""
    print("=" * 80)
    print("ScyllaDB Cluster Test")
    print("=" * 80)
    
    cluster = None
    session = None
    
    try:
        # Connect to ScyllaDB
        cluster, session = connect_with_retry()
        
        # Run tests
        create_keyspace(session)
        create_table(session)
        insert_test_data(session)
        query_data(session)
        
        # Optional cleanup
        # cleanup(session)
        
        print("\n" + "=" * 80)
        print("✓ All tests passed successfully!")
        print("=" * 80)
        
    except Exception as e:
        print(f"\n✗ Test failed with error: {e}")
        sys.exit(1)
    
    finally:
        if cluster:
            cluster.shutdown()
            print("\nConnection closed.")


if __name__ == "__main__":
    main()
