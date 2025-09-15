#!/bin/bash

# PostgreSQL Restore Script
# Usage: ./restore.sh <backup_file> [database_name] [container_name]

set -e

# Check if backup file is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <backup_file> [database_name] [container_name]"
    echo "Example: $0 ./backups/devdb_backup_20231201_120000.sql.gz"
    exit 1
fi

BACKUP_FILE="$1"
DB_NAME="${2:-devdb}"
CONTAINER_NAME="${3:-postgres_dev}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}PostgreSQL Restore Script${NC}"
echo "========================================"

# Check if backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
    echo -e "${RED}Error: Backup file '$BACKUP_FILE' does not exist${NC}"
    exit 1
fi

# Check if container is running
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo -e "${RED}Error: Container '$CONTAINER_NAME' is not running${NC}"
    echo "Available containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}"
    exit 1
fi

echo -e "Restoring database: ${GREEN}$DB_NAME${NC}"
echo -e "To container: ${GREEN}$CONTAINER_NAME${NC}"
echo -e "From backup file: ${GREEN}$BACKUP_FILE${NC}"

# Check if file is compressed
if [[ "$BACKUP_FILE" == *.gz ]]; then
    echo "Detected compressed backup file"
    RESTORE_COMMAND="gunzip -c \"$BACKUP_FILE\" | docker exec -i \"$CONTAINER_NAME\" psql -U postgres -d \"$DB_NAME\""
else
    RESTORE_COMMAND="docker exec -i \"$CONTAINER_NAME\" psql -U postgres -d \"$DB_NAME\" < \"$BACKUP_FILE\""
fi

# Confirm before proceeding
echo -e "${YELLOW}WARNING: This will overwrite the existing database '$DB_NAME'${NC}"
read -p "Are you sure you want to continue? (y/N): " -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Restore cancelled."
    exit 0
fi

# Drop existing connections (optional but recommended)
echo "Terminating active connections to database..."
docker exec "$CONTAINER_NAME" psql -U postgres -c "
SELECT pg_terminate_backend(pid) 
FROM pg_stat_activity 
WHERE datname = '$DB_NAME' AND pid <> pg_backend_pid();" || true

# Perform restore
echo "Starting restore..."
if [[ "$BACKUP_FILE" == *.gz ]]; then
    if gunzip -c "$BACKUP_FILE" | docker exec -i "$CONTAINER_NAME" psql -U postgres -d "$DB_NAME"; then
        echo -e "${GREEN}✓ Restore completed successfully!${NC}"
    else
        echo -e "${RED}✗ Restore failed!${NC}"
        exit 1
    fi
else
    if docker exec -i "$CONTAINER_NAME" psql -U postgres -d "$DB_NAME" < "$BACKUP_FILE"; then
        echo -e "${GREEN}✓ Restore completed successfully!${NC}"
    else
        echo -e "${RED}✗ Restore failed!${NC}"
        exit 1
    fi
fi

# Verify restore
echo "Verifying restore..."
TABLE_COUNT=$(docker exec "$CONTAINER_NAME" psql -U postgres -d "$DB_NAME" -t -c "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';" | tr -d ' ')
echo -e "Tables restored: ${GREEN}$TABLE_COUNT${NC}"

echo "========================================"
echo -e "${GREEN}Restore process completed!${NC}"
