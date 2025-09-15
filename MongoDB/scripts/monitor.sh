#!/bin/bash

# MongoDB Monitoring Script
# This script monitors MongoDB replica set status and performance

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

# Check if MongoDB containers are running
if ! docker ps --format "table {{.Names}}" | grep -q "mongo"; then
    echo -e "${RED}No MongoDB containers found running${NC}"
    exit 1
fi

echo -e "${BLUE}MongoDB Monitoring Dashboard${NC}"
echo -e "${BLUE}============================${NC}"
echo

# Function to check single node
check_single_node() {
    echo -e "${YELLOW}Single Node Status:${NC}"
    if docker ps --format "table {{.Names}}" | grep -q "mongodb_single"; then
        echo -e "${GREEN}✓ MongoDB Single Node is running${NC}"
        
        # Check health
        HEALTH=$(docker inspect mongodb_single --format='{{.State.Health.Status}}' 2>/dev/null || echo "unknown")
        echo -e "${BLUE}Health Status: ${HEALTH}${NC}"
        
        # Get basic stats
        docker exec mongodb_single mongosh \
            --username "${MONGO_INITDB_ROOT_USERNAME}" \
            --password "${MONGO_INITDB_ROOT_PASSWORD}" \
            --authenticationDatabase admin \
            --quiet \
            --eval "
            print('Database Stats:');
            print('==============');
            var stats = db.runCommand({serverStatus: 1});
            print('Uptime: ' + Math.floor(stats.uptime / 3600) + ' hours');
            print('Connections: ' + stats.connections.current + '/' + stats.connections.available);
            print('Memory Usage: ' + Math.floor(stats.mem.resident) + ' MB');
            print('');
            print('Databases:');
            db.adminCommand('listDatabases').databases.forEach(function(db) {
                print('  - ' + db.name + ' (' + Math.floor(db.sizeOnDisk/1024/1024) + ' MB)');
            });
            "
    else
        echo -e "${RED}✗ MongoDB Single Node is not running${NC}"
    fi
    echo
}

# Function to check replica set
check_replica_set() {
    echo -e "${YELLOW}Replica Set Status:${NC}"
    if docker ps --format "table {{.Names}}" | grep -q "mongodb_primary"; then
        echo -e "${GREEN}✓ MongoDB Replica Set is running${NC}"
        
        # Check replica set status
        docker exec mongodb_primary mongosh \
            --username "${MONGO_INITDB_ROOT_USERNAME}" \
            --password "${MONGO_INITDB_ROOT_PASSWORD}" \
            --authenticationDatabase admin \
            --quiet \
            --eval "
            try {
                var status = rs.status();
                print('Replica Set: ' + status.set);
                print('==============');
                status.members.forEach(function(member) {
                    var state = member.stateStr;
                    var health = member.health === 1 ? '✓' : '✗';
                    var lag = '';
                    if (state === 'SECONDARY' && member.optimeDate && status.date) {
                        var lagMs = status.date - member.optimeDate;
                        lag = ' (lag: ' + Math.floor(lagMs/1000) + 's)';
                    }
                    print(health + ' ' + member.name + ' - ' + state + lag);
                });
                print('');
                
                // Get primary stats
                var primary = status.members.find(m => m.stateStr === 'PRIMARY');
                if (primary) {
                    print('Primary Node Stats:');
                    print('==================');
                    var stats = db.runCommand({serverStatus: 1});
                    print('Uptime: ' + Math.floor(stats.uptime / 3600) + ' hours');
                    print('Connections: ' + stats.connections.current + '/' + stats.connections.available);
                    print('Memory Usage: ' + Math.floor(stats.mem.resident) + ' MB');
                    print('Oplog Size: ' + Math.floor(stats.repl.logSizeMB) + ' MB');
                    print('');
                }
                
                print('Databases:');
                db.adminCommand('listDatabases').databases.forEach(function(db) {
                    print('  - ' + db.name + ' (' + Math.floor(db.sizeOnDisk/1024/1024) + ' MB)');
                });
            } catch(e) {
                print('Error getting replica set status: ' + e);
            }
            "
    else
        echo -e "${RED}✗ MongoDB Replica Set is not running${NC}"
    fi
    echo
}

# Function to check container health
check_container_health() {
    echo -e "${YELLOW}Container Health:${NC}"
    docker ps --filter "name=mongo" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo
}

# Function to show resource usage
check_resource_usage() {
    echo -e "${YELLOW}Resource Usage:${NC}"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" $(docker ps --filter "name=mongo" --format "{{.Names}}" | tr '\n' ' ') 2>/dev/null || echo "No MongoDB containers running"
    echo
}

# Function to check MongoDB Express
check_mongo_express() {
    echo -e "${YELLOW}MongoDB Express:${NC}"
    if docker ps --format "table {{.Names}}" | grep -q "mongo_express"; then
        MONGO_EXPRESS_PORT=${MONGO_EXPRESS_PORT:-8081}
        echo -e "${GREEN}✓ MongoDB Express is running${NC}"
        echo -e "${BLUE}URL: http://localhost:${MONGO_EXPRESS_PORT}${NC}"
    else
        echo -e "${RED}✗ MongoDB Express is not running${NC}"
    fi
    echo
}

# Function for continuous monitoring
continuous_monitor() {
    echo -e "${BLUE}Starting continuous monitoring (press Ctrl+C to stop)...${NC}"
    echo
    
    while true; do
        clear
        echo -e "${BLUE}MongoDB Monitoring Dashboard - $(date)${NC}"
        echo -e "${BLUE}================================================${NC}"
        echo
        
        check_container_health
        check_resource_usage
        
        if docker ps --format "table {{.Names}}" | grep -q "mongodb_primary"; then
            check_replica_set
        elif docker ps --format "table {{.Names}}" | grep -q "mongodb_single"; then
            check_single_node
        fi
        
        check_mongo_express
        
        echo -e "${YELLOW}Refreshing in 10 seconds...${NC}"
        sleep 10
    done
}

# Main monitoring logic
case "${1:-status}" in
    "status")
        check_container_health
        if docker ps --format "table {{.Names}}" | grep -q "mongodb_primary"; then
            check_replica_set
        elif docker ps --format "table {{.Names}}" | grep -q "mongodb_single"; then
            check_single_node
        fi
        check_mongo_express
        ;;
    "continuous"|"watch")
        continuous_monitor
        ;;
    "resources")
        check_resource_usage
        ;;
    "help")
        echo "Usage: $0 [status|continuous|watch|resources|help]"
        echo "  status     - Show current status (default)"
        echo "  continuous - Continuous monitoring"
        echo "  watch      - Alias for continuous"
        echo "  resources  - Show resource usage"
        echo "  help       - Show this help"
        ;;
    *)
        echo -e "${RED}Unknown option: $1${NC}"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac
