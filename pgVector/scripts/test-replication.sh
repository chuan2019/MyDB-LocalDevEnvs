#!/bin/bash

# Load environment variables
if [ -f "../.env" ]; then
    export $(cat ../.env | grep -v '^#' | xargs)
fi

# Set database credentials from environment variables
POSTGRES_USER=${POSTGRES_USER:-pgvector_user}
POSTGRES_DB=${POSTGRES_DB:-pgvector_db}
PRIMARY_HOST=${PRIMARY_HOST:-pgvector-primary}
REPLICA_HOST=${REPLICA_HOST:-pgvector-replica}
PRIMARY_PORT=${PRIMARY_PORT:-5432}
REPLICA_PORT=${REPLICA_PORT:-5433}

# Set PGPASSWORD for non-interactive authentication
export PGPASSWORD="${POSTGRES_PASSWORD}"

echo "Testing PostgreSQL replication setup..."
echo "Primary: $PRIMARY_HOST:$PRIMARY_PORT"
echo "Replica: $REPLICA_HOST:$REPLICA_PORT"
echo "Database: $POSTGRES_DB, User: $POSTGRES_USER"
echo "----------------------------------------"

# Wait for the primary database to be ready
echo "Waiting for primary database to be ready..."
cd "$(dirname "$0")/.." || exit 1
until docker compose -f docker-compose-cluster.yml exec -T postgres-primary pg_isready -U "$POSTGRES_USER" > /dev/null 2>&1; do
  echo "Primary database not ready, waiting 2 seconds..."
  sleep 2
done
echo "Primary database is ready!"

# Wait for the replica database to be ready
echo "Waiting for replica database to be ready..."
until docker compose -f docker-compose-cluster.yml exec -T postgres-replica pg_isready -U "$POSTGRES_USER" > /dev/null 2>&1; do
  echo "Replica database not ready, waiting 2 seconds..."
  sleep 2
done
echo "Replica database is ready!"

# Check the replication status on primary
echo "Checking replication status on primary..."
REPL_STATUS=$(docker compose -f docker-compose-cluster.yml exec -T postgres-primary psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "SELECT application_name, state, sync_state FROM pg_stat_replication;" 2>/dev/null)

if [ -n "$REPL_STATUS" ]; then
  echo "Replication connections found:"
  echo "$REPL_STATUS"
else
  echo "No replication connections found on primary."
fi

# Test data consistency
echo "Testing data consistency..."
TEST_TABLE="replication_test_$(date +%s)"

# Create test table and insert data on primary
echo "Creating test table on primary..."
psql -h "$PRIMARY_HOST" -p "$PRIMARY_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "
    CREATE TABLE $TEST_TABLE (id SERIAL PRIMARY KEY, test_data TEXT, created_at TIMESTAMP DEFAULT NOW());
    INSERT INTO $TEST_TABLE (test_data) VALUES ('replication test data');
" > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "Test table created and data inserted on primary."
    
    # Wait for replication to sync
    echo "Waiting 5 seconds for replication to sync..."
    sleep 5
    
    # Check if data exists on replica
    echo "Checking if data exists on replica..."
    REPLICA_DATA=$(psql -h "$REPLICA_HOST" -p "$REPLICA_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "SELECT test_data FROM $TEST_TABLE LIMIT 1;" 2>/dev/null | tr -d '[:space:]')
    
    if [ "$REPLICA_DATA" = "replicationtestdata" ]; then
        echo "PASSED: Replication test - Data successfully replicated to replica!"
    else
        echo "FAILED: Replication test - Data not found on replica."
        echo "Expected: 'replication test data', Got: '$REPLICA_DATA'"
    fi
    
    # Clean up test table
    echo "Cleaning up test table..."
    psql -h "$PRIMARY_HOST" -p "$PRIMARY_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "DROP TABLE $TEST_TABLE;" > /dev/null 2>&1
else
    echo "FAILED: Could not create test table on primary."
    exit 1
fi

echo "Replication test completed."