#!/bin/bash

# MongoDB Replica Set Initialization Script
# This script initializes a MongoDB replica set

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

echo -e "${BLUE}Initializing MongoDB Replica Set: ${MONGO_REPLICA_SET_NAME}${NC}"

# Wait for MongoDB primary to be ready
echo -e "${YELLOW}Waiting for MongoDB primary to be ready...${NC}"
sleep 15

# Check if replica set is already initialized
echo -e "${BLUE}Checking if replica set is already initialized...${NC}"
REPLICA_STATUS=$(docker exec mongodb_primary mongosh --username "${MONGO_INITDB_ROOT_USERNAME}" --password "${MONGO_INITDB_ROOT_PASSWORD}" --authenticationDatabase admin --quiet --eval "try { rs.status().ok } catch(e) { 0 }" 2>/dev/null || echo "0")

if [ "$REPLICA_STATUS" = "1" ]; then
    echo -e "${YELLOW}Replica set is already initialized${NC}"
    echo -e "${BLUE}Current replica set status:${NC}"
    docker exec mongodb_primary mongosh --username "${MONGO_INITDB_ROOT_USERNAME}" --password "${MONGO_INITDB_ROOT_PASSWORD}" --authenticationDatabase admin --eval "rs.status()"
    exit 0
fi

# Initialize replica set
echo -e "${BLUE}Initializing replica set...${NC}"

# Create the replica set configuration
REPLICA_CONFIG=$(cat <<EOF
{
  _id: "${MONGO_REPLICA_SET_NAME}",
  members: [
    {
      _id: 0,
      host: "mongodb-primary:27017",
      priority: 2
    },
    {
      _id: 1,
      host: "mongodb-secondary-1:27017",
      priority: 1
    },
    {
      _id: 2,
      host: "mongodb-secondary-2:27017",
      priority: 1
    }
  ]
}
EOF
)

# Execute replica set initialization
docker exec mongodb_primary mongosh --username "${MONGO_INITDB_ROOT_USERNAME}" --password "${MONGO_INITDB_ROOT_PASSWORD}" --authenticationDatabase admin --eval "
try {
  var config = ${REPLICA_CONFIG};
  rs.initiate(config);
  print('Replica set initiated successfully');
} catch(e) {
  print('Error initiating replica set: ' + e);
  quit(1);
}
"

# Wait for replica set to stabilize
echo -e "${YELLOW}Waiting for replica set to stabilize...${NC}"
sleep 20

# Check replica set status
echo -e "${BLUE}Checking replica set status...${NC}"
for i in {1..10}; do
    STATUS=$(docker exec mongodb_primary mongosh --username "${MONGO_INITDB_ROOT_USERNAME}" --password "${MONGO_INITDB_ROOT_PASSWORD}" --authenticationDatabase admin --quiet --eval "
    try {
        var status = rs.status();
        var primary = status.members.find(m => m.stateStr === 'PRIMARY');
        var secondaries = status.members.filter(m => m.stateStr === 'SECONDARY');
        if (primary && secondaries.length >= 2) {
            print('READY');
        } else {
            print('WAITING');
        }
    } catch(e) {
        print('ERROR');
    }
    " 2>/dev/null || echo "ERROR")
    
    if [ "$STATUS" = "READY" ]; then
        echo -e "${GREEN}Replica set is ready!${NC}"
        break
    elif [ "$i" -eq 10 ]; then
        echo -e "${RED}Replica set initialization timed out${NC}"
        exit 1
    else
        echo -e "${YELLOW}Waiting for replica set to be ready... (attempt $i/10)${NC}"
        sleep 10
    fi
done

# Display final status
echo -e "${BLUE}Final replica set status:${NC}"
docker exec mongodb_primary mongosh --username "${MONGO_INITDB_ROOT_USERNAME}" --password "${MONGO_INITDB_ROOT_PASSWORD}" --authenticationDatabase admin --eval "rs.status()"

# Create additional users for replica set
echo -e "${BLUE}Creating replica set users...${NC}"
docker exec mongodb_primary mongosh --username "${MONGO_INITDB_ROOT_USERNAME}" --password "${MONGO_INITDB_ROOT_PASSWORD}" --authenticationDatabase admin --eval "
use admin;

// Create cluster monitor user
try {
    db.createUser({
        user: 'clusterMonitor',
        pwd: 'monitor123',
        roles: [
            { role: 'clusterMonitor', db: 'admin' },
            { role: 'read', db: 'local' }
        ]
    });
    print('Cluster monitor user created');
} catch(e) {
    print('Cluster monitor user might already exist: ' + e);
}

// Create backup user
try {
    db.createUser({
        user: 'backup',
        pwd: 'backup123',
        roles: [
            { role: 'backup', db: 'admin' },
            { role: 'restore', db: 'admin' }
        ]
    });
    print('Backup user created');
} catch(e) {
    print('Backup user might already exist: ' + e);
}
"

echo -e "${GREEN}MongoDB Replica Set initialization completed successfully!${NC}"
echo -e "${BLUE}Connection string: mongodb://${MONGO_INITDB_ROOT_USERNAME}:${MONGO_INITDB_ROOT_PASSWORD}@localhost:27017,localhost:27018,localhost:27019/?replicaSet=${MONGO_REPLICA_SET_NAME}${NC}"
