#!/bin/bash

# PostgreSQL Replication Test Script
# Tests write/read operations across cluster

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

DB_NAME="devdb"
TEST_TABLE="replication_test"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_test() {
    echo -e "\n${YELLOW}TEST: $1${NC}"
}

# Test 1: Basic connectivity
test_connectivity() {
    print_test "Basic Connectivity"
    
    echo "Testing connections to all nodes..."
    
    # Test primary
    if docker exec postgres_primary psql -U postgres -d "$DB_NAME" -c "SELECT 'Primary connection OK' as status;" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Primary connection successful${NC}"
    else
        echo -e "${RED}✗ Primary connection failed${NC}"
        return 1
    fi
    
    # Test replicas
    for replica in postgres_replica_1 postgres_replica_2; do
        if docker exec "$replica" psql -U postgres -d "$DB_NAME" -c "SELECT 'Replica connection OK' as status;" >/dev/null 2>&1; then
            echo -e "${GREEN}✓ $replica connection successful${NC}"
        else
            echo -e "${RED}✗ $replica connection failed${NC}"
            return 1
        fi
    done
    
    # Test load balancer
    if docker exec postgres_loadbalancer nc -z localhost 5430 && docker exec postgres_loadbalancer nc -z localhost 5431; then
        echo -e "${GREEN}✓ Load balancer ports accessible${NC}"
    else
        echo -e "${RED}✗ Load balancer ports not accessible${NC}"
        return 1
    fi
}

# Test 2: Create test table and data
test_write_operations() {
    print_test "Write Operations"
    
    echo "Creating test table and inserting data on primary..."
    
    # Create test table
    docker exec postgres_primary psql -U postgres -d "$DB_NAME" -c "
    DROP TABLE IF EXISTS $TEST_TABLE;
    CREATE TABLE $TEST_TABLE (
        id SERIAL PRIMARY KEY,
        test_data VARCHAR(100),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    "
    
    # Insert test data
    docker exec postgres_primary psql -U postgres -d "$DB_NAME" -c "
    INSERT INTO $TEST_TABLE (test_data) VALUES 
    ('Replication test data 1 - $TIMESTAMP'),
    ('Replication test data 2 - $TIMESTAMP'),
    ('Replication test data 3 - $TIMESTAMP');
    "
    
    # Verify data on primary
    ROW_COUNT=$(docker exec postgres_primary psql -U postgres -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM $TEST_TABLE;" | tr -d ' ')
    
    if [ "$ROW_COUNT" = "3" ]; then
        echo -e "${GREEN}✓ Data written to primary ($ROW_COUNT rows)${NC}"
    else
        echo -e "${RED}✗ Data write to primary failed (expected 3 rows, got $ROW_COUNT)${NC}"
        return 1
    fi
}

# Test 3: Check replication delay
test_replication_delay() {
    print_test "Replication Synchronization"
    
    echo "Waiting for replication to catch up..."
    sleep 3
    
    # Check data on replicas
    for replica in postgres_replica_1 postgres_replica_2; do
        REPLICA_COUNT=$(docker exec "$replica" psql -U postgres -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM $TEST_TABLE;" 2>/dev/null | tr -d ' ' || echo "0")
        
        if [ "$REPLICA_COUNT" = "3" ]; then
            echo -e "${GREEN}✓ $replica has replicated data ($REPLICA_COUNT rows)${NC}"
        else
            echo -e "${RED}✗ $replica replication incomplete (expected 3 rows, got $REPLICA_COUNT)${NC}"
            
            # Show replication status for debugging
            echo "Checking replication status..."
            docker exec postgres_primary psql -U postgres -c "SELECT client_addr, state, sync_state FROM pg_stat_replication;"
        fi
    done
}

# Test 4: Read-only verification
test_readonly_replicas() {
    print_test "Read-Only Replica Verification"
    
    for replica in postgres_replica_1 postgres_replica_2; do
        echo "Testing read-only status of $replica..."
        
        # Try to insert data (should fail)
        if docker exec "$replica" psql -U postgres -d "$DB_NAME" -c "INSERT INTO $TEST_TABLE (test_data) VALUES ('Should fail');" >/dev/null 2>&1; then
            echo -e "${RED}✗ $replica allows writes (should be read-only!)${NC}"
        else
            echo -e "${GREEN}✓ $replica correctly rejects writes${NC}"
        fi
        
        # Try to read data (should work)
        if docker exec "$replica" psql -U postgres -d "$DB_NAME" -c "SELECT * FROM $TEST_TABLE LIMIT 1;" >/dev/null 2>&1; then
            echo -e "${GREEN}✓ $replica allows reads${NC}"
        else
            echo -e "${RED}✗ $replica cannot read data${NC}"
        fi
    done
}

# Test 5: Load balancer routing
test_load_balancer() {
    print_test "Load Balancer Routing"
    
    echo "Testing write port (should route to primary)..."
    
    # Test write through load balancer
    if docker run --rm --network local-dev_postgres_cluster_network postgres:16-alpine psql -h haproxy -p 5430 -U postgres -d "$DB_NAME" -c "INSERT INTO $TEST_TABLE (test_data) VALUES ('Via load balancer - $TIMESTAMP');" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Write through load balancer successful${NC}"
    else
        echo -e "${RED}✗ Write through load balancer failed${NC}"
    fi
    
    echo "Testing read port (should route to replicas)..."
    
    # Test read through load balancer
    if docker run --rm --network local-dev_postgres_cluster_network postgres:16-alpine psql -h haproxy -p 5431 -U postgres -d "$DB_NAME" -c "SELECT COUNT(*) FROM $TEST_TABLE;" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Read through load balancer successful${NC}"
    else
        echo -e "${RED}✗ Read through load balancer failed${NC}"
    fi
}

# Test 6: Failover simulation (optional)
test_failover_simulation() {
    print_test "Failover Simulation (Manual)"
    
    echo -e "${YELLOW}Manual failover test:${NC}"
    echo "1. Stop primary: docker stop postgres_primary"
    echo "2. Wait 30 seconds"
    echo "3. Check HAProxy stats: http://localhost:8404/stats"
    echo "4. Restart primary: docker start postgres_primary"
    echo "5. Monitor replication catch-up"
    echo ""
    echo -e "${YELLOW}Note: This test requires manual intervention${NC}"
}

# Performance test
test_performance() {
    print_test "Basic Performance Test"
    
    echo "Running basic performance test..."
    
    # Simple performance test - insert many rows
    docker exec postgres_primary psql -U postgres -d "$DB_NAME" -c "
    INSERT INTO $TEST_TABLE (test_data)
    SELECT 'Performance test row ' || generate_series(1, 1000);
    "
    
    # Check final count
    FINAL_COUNT=$(docker exec postgres_primary psql -U postgres -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM $TEST_TABLE;" | tr -d ' ')
    echo -e "Total rows in test table: ${GREEN}$FINAL_COUNT${NC}"
    
    # Wait for replication
    echo "Waiting for replication..."
    sleep 5
    
    # Check replica counts
    for replica in postgres_replica_1 postgres_replica_2; do
        REPLICA_COUNT=$(docker exec "$replica" psql -U postgres -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM $TEST_TABLE;" 2>/dev/null | tr -d ' ' || echo "0")
        echo -e "$replica count: ${GREEN}$REPLICA_COUNT${NC}"
    done
}

# Cleanup function
cleanup_test() {
    print_test "Cleanup"
    
    echo "Removing test table..."
    docker exec postgres_primary psql -U postgres -d "$DB_NAME" -c "DROP TABLE IF EXISTS $TEST_TABLE;" >/dev/null 2>&1 || true
    echo -e "${GREEN}✓ Cleanup completed${NC}"
}

# Main execution
print_header "PostgreSQL Replication Test Suite"
echo "Starting replication tests at: $(date)"

# Check if cluster is running
if ! docker ps | grep -q postgres_primary; then
    echo -e "${RED}Error: PostgreSQL cluster is not running${NC}"
    echo "Start the cluster with: docker-compose -f docker-compose-cluster.yml up -d"
    exit 1
fi

# Run tests
FAILED_TESTS=0

test_connectivity || ((FAILED_TESTS++))
test_write_operations || ((FAILED_TESTS++))
test_replication_delay || ((FAILED_TESTS++))
test_readonly_replicas || ((FAILED_TESTS++))
test_load_balancer || ((FAILED_TESTS++))
test_performance || ((FAILED_TESTS++))
test_failover_simulation
cleanup_test

# Summary
print_header "Test Summary"
if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed successfully!${NC}"
    echo -e "Replication is working correctly."
else
    echo -e "${RED}✗ $FAILED_TESTS test(s) failed${NC}"
    echo -e "Check the output above for details."
fi

echo ""
echo "Test completed at: $(date)"
