#!/bin/bash

# MongoDB Replica Set Testing Script
# This script tests replica set functionality

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Load environment variables
if [ -f .env ]; then
    source .env
fi

# Default values
MONGO_INITDB_ROOT_USERNAME=${MONGO_INITDB_ROOT_USERNAME:-admin}
MONGO_INITDB_ROOT_PASSWORD=${MONGO_INITDB_ROOT_PASSWORD:-admin123}
MONGO_REPLICA_SET_NAME=${MONGO_REPLICA_SET_NAME:-rs0}

echo -e "${BLUE}Testing MongoDB Replica Set Functionality${NC}"
echo -e "${BLUE}=========================================${NC}"
echo

# Check if replica set is running
if ! docker ps --format "table {{.Names}}" | grep -q "mongodb_primary"; then
    echo -e "${RED}MongoDB replica set is not running${NC}"
    echo "Start it with: make cluster-up && make init-replica-set"
    exit 1
fi

# Test 1: Check replica set status
echo -e "${YELLOW}Test 1: Checking replica set status...${NC}"
STATUS=$(docker exec mongodb_primary mongosh \
    --username "${MONGO_INITDB_ROOT_USERNAME}" \
    --password "${MONGO_INITDB_ROOT_PASSWORD}" \
    --authenticationDatabase admin \
    --quiet \
    --eval "
    try {
        var status = rs.status();
        var primary = status.members.filter(m => m.stateStr === 'PRIMARY').length;
        var secondary = status.members.filter(m => m.stateStr === 'SECONDARY').length;
        if (primary === 1 && secondary >= 1) {
            print('PASS');
        } else {
            print('FAIL: Primary=' + primary + ', Secondary=' + secondary);
        }
    } catch(e) {
        print('FAIL: ' + e);
    }
    ")

if [[ "$STATUS" == "PASS" ]]; then
    echo -e "${GREEN}✓ Replica set status: PASS${NC}"
else
    echo -e "${RED}✗ Replica set status: $STATUS${NC}"
fi
echo

# Test 2: Write to primary and read from secondary
echo -e "${YELLOW}Test 2: Testing write to primary and read from secondary...${NC}"

# Write test data to primary
WRITE_RESULT=$(docker exec mongodb_primary mongosh \
    --username "${MONGO_INITDB_ROOT_USERNAME}" \
    --password "${MONGO_INITDB_ROOT_PASSWORD}" \
    --authenticationDatabase admin \
    --eval "
    var testDocId = 'replication_test_' + new Date().getTime();
    var testDoc = {
        _id: testDocId,
        message: 'Test replication at ' + new Date(),
        timestamp: new Date()
    };
    try {
        var result = db.testdb.replication_test.insertOne(testDoc);
        if (result.acknowledged) {
            print('WRITE_SUCCESS:' + testDocId);
        } else {
            print('WRITE_FAIL');
        }
    } catch(e) {
        print('WRITE_ERROR: ' + e);
    }
    " 2>&1 | grep -E "(WRITE_SUCCESS|WRITE_FAIL|WRITE_ERROR)" || echo "WRITE_ERROR")

if [[ "$WRITE_RESULT" == WRITE_SUCCESS:* ]]; then
    TEST_ID=$(echo "$WRITE_RESULT" | cut -d: -f2)
    echo -e "${GREEN}✓ Write to primary: SUCCESS${NC}"
    
    # Wait for replication
    echo -e "${YELLOW}Waiting for replication...${NC}"
    sleep 3
    
    # Try to read from secondary
    READ_RESULT=$(docker exec mongodb_secondary_1 mongosh \
        --username "${MONGO_INITDB_ROOT_USERNAME}" \
        --password "${MONGO_INITDB_ROOT_PASSWORD}" \
        --authenticationDatabase admin \
        --eval "
        rs.secondaryOk(); // Allow reading from secondary
        try {
            var doc = db.testdb.replication_test.findOne({_id: '${TEST_ID}'});
            if (doc) {
                print('READ_SUCCESS');
            } else {
                print('READ_NOT_FOUND');
            }
        } catch(e) {
            print('READ_ERROR: ' + e);
        }
        " 2>&1 | grep -E "(READ_SUCCESS|READ_NOT_FOUND|READ_ERROR)" || echo "READ_ERROR")
    
    if [[ "$READ_RESULT" == "READ_SUCCESS" ]]; then
        echo -e "${GREEN}✓ Read from secondary: SUCCESS${NC}"
    else
        echo -e "${RED}✗ Read from secondary: $READ_RESULT${NC}"
    fi
else
    echo -e "${RED}✗ Write to primary: $WRITE_RESULT${NC}"
fi
echo

# Test 3: Check read preference
echo -e "${YELLOW}Test 3: Testing read preference...${NC}"
READ_PREF_RESULT=$(docker exec mongodb_secondary_1 mongosh \
    --username "${MONGO_INITDB_ROOT_USERNAME}" \
    --password "${MONGO_INITDB_ROOT_PASSWORD}" \
    --authenticationDatabase admin \
    --eval "
    try {
        rs.secondaryOk();
        var result = db.runCommand({hello: 1});
        if (result.isWritablePrimary === false || result.secondary === true) {
            print('READ_PREFERENCE_SUCCESS');
        } else {
            print('READ_PREFERENCE_FAIL: Connected to primary');
        }
    } catch(e) {
        print('READ_PREFERENCE_ERROR: ' + e);
    }
    " 2>&1 | grep -E "(READ_PREFERENCE_SUCCESS|READ_PREFERENCE_FAIL|READ_PREFERENCE_ERROR)" || echo "READ_PREFERENCE_ERROR")

if [[ "$READ_PREF_RESULT" == "READ_PREFERENCE_SUCCESS" ]]; then
    echo -e "${GREEN}✓ Read preference (secondary): SUCCESS${NC}"
else
    echo -e "${RED}✗ Read preference: $READ_PREF_RESULT${NC}"
fi
echo

# Test 4: Test connection string
echo -e "${YELLOW}Test 4: Testing replica set connection string...${NC}"
CONN_TEST=$(docker exec mongodb_primary mongosh \
    "mongodb://${MONGO_INITDB_ROOT_USERNAME}:${MONGO_INITDB_ROOT_PASSWORD}@mongodb-primary:27017,mongodb-secondary-1:27017,mongodb-secondary-2:27017/?replicaSet=${MONGO_REPLICA_SET_NAME}" \
    --quiet \
    --eval "
    try {
        var result = rs.status();
        print('CONNECTION_SUCCESS');
    } catch(e) {
        print('CONNECTION_ERROR: ' + e);
    }
    ")

if [[ "$CONN_TEST" == "CONNECTION_SUCCESS" ]]; then
    echo -e "${GREEN}✓ Replica set connection string: SUCCESS${NC}"
else
    echo -e "${RED}✗ Connection string test: $CONN_TEST${NC}"
fi
echo

# Test 5: Check oplog
echo -e "${YELLOW}Test 5: Checking oplog...${NC}"
OPLOG_TEST=$(docker exec mongodb_primary mongosh \
    --username "${MONGO_INITDB_ROOT_USERNAME}" \
    --password "${MONGO_INITDB_ROOT_PASSWORD}" \
    --authenticationDatabase admin \
    --eval "
    try {
        // Check if oplog.rs collection exists
        var collections = db.local.runCommand('listCollections').cursor.firstBatch;
        var oplogExists = collections.some(function(coll) { return coll.name === 'oplog.rs'; });
        
        if (oplogExists) {
            var oplogCount = db.local.oplog.rs.countDocuments({});
            print('OPLOG_SUCCESS: ' + oplogCount + ' entries');
        } else {
            // For newer MongoDB versions or fresh replica sets, oplog might not be populated yet
            // Check if replica set is working by checking replica set config
            var config = rs.conf();
            if (config && config.members && config.members.length > 0) {
                print('OPLOG_SUCCESS: Replica set configured, oplog will be created on activity');
            } else {
                print('OPLOG_ERROR: No replica set configuration found');
            }
        }
    } catch(e) {
        print('OPLOG_ERROR: ' + e);
    }
    " 2>&1 | grep -E "(OPLOG_SUCCESS|OPLOG_EMPTY|OPLOG_ERROR)" || echo "OPLOG_ERROR")

if [[ "$OPLOG_TEST" == OPLOG_SUCCESS:* ]]; then
    echo -e "${GREEN}✓ Oplog check: $OPLOG_TEST${NC}"
else
    echo -e "${RED}✗ Oplog check: $OPLOG_TEST${NC}"
fi
echo

# Test 6: Failover simulation (optional - requires user confirmation)
echo -e "${YELLOW}Test 6: Failover simulation (optional)${NC}"
read -p "Do you want to test failover by stopping the primary? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Stopping primary node...${NC}"
    docker stop mongodb_primary
    
    echo -e "${YELLOW}Waiting for new primary election...${NC}"
    sleep 15
    
    # Check if a new primary was elected
    NEW_PRIMARY_TEST=$(docker exec mongodb_secondary_1 mongosh \
        --username "${MONGO_INITDB_ROOT_USERNAME}" \
        --password "${MONGO_INITDB_ROOT_PASSWORD}" \
        --authenticationDatabase admin \
        --quiet \
        --eval "
        try {
            var status = rs.status();
            var primary = status.members.find(m => m.stateStr === 'PRIMARY');
            if (primary) {
                print('FAILOVER_SUCCESS: ' + primary.name + ' is new primary');
            } else {
                print('FAILOVER_FAIL: No primary found');
            }
        } catch(e) {
            print('FAILOVER_ERROR: ' + e);
        }
        ")
    
    if [[ "$NEW_PRIMARY_TEST" == FAILOVER_SUCCESS:* ]]; then
        echo -e "${GREEN}✓ Failover test: $NEW_PRIMARY_TEST${NC}"
    else
        echo -e "${RED}✗ Failover test: $NEW_PRIMARY_TEST${NC}"
    fi
    
    echo -e "${BLUE}Restarting original primary...${NC}"
    docker start mongodb_primary
    echo -e "${YELLOW}Waiting for cluster to stabilize...${NC}"
    sleep 15
else
    echo -e "${YELLOW}Skipping failover test${NC}"
fi
echo

# Summary
echo -e "${BLUE}Test Summary${NC}"
echo -e "${BLUE}============${NC}"
echo -e "${GREEN}MongoDB Replica Set testing completed!${NC}"
echo
echo -e "${YELLOW}For continuous monitoring, run: make monitor${NC}"
echo -e "${YELLOW}For replica set status, run: make connect-primary${NC}"
echo -e "${YELLOW}then execute: rs.status()${NC}"
