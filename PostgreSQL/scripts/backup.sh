#!/bin/bash

# PostgreSQL Backup Script
# Usage: ./backup.sh [database_name] [container_name]

set -e

# Default values
DB_NAME="${1:-devdb}"
CONTAINER_NAME="${2:-postgres_dev}"
BACKUP_DIR="./backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_backup_${TIMESTAMP}.sql"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}PostgreSQL Backup Script${NC}"
echo "========================================"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Check if container is running
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo -e "${RED}Error: Container '$CONTAINER_NAME' is not running${NC}"
    echo "Available containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}"
    exit 1
fi

echo -e "Creating backup of database: ${GREEN}$DB_NAME${NC}"
echo -e "From container: ${GREEN}$CONTAINER_NAME${NC}"
echo -e "Backup file: ${GREEN}$BACKUP_FILE${NC}"

# Perform backup
echo "Starting backup..."
if docker exec "$CONTAINER_NAME" pg_dump -U postgres -d "$DB_NAME" > "$BACKUP_FILE"; then
    echo -e "${GREEN}✓ Backup completed successfully!${NC}"
    echo -e "Backup saved to: ${GREEN}$BACKUP_FILE${NC}"
    
    # Show backup file size
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo -e "Backup size: ${GREEN}$BACKUP_SIZE${NC}"
    
    # Compress backup
    echo "Compressing backup..."
    if gzip "$BACKUP_FILE"; then
        echo -e "${GREEN}✓ Backup compressed successfully!${NC}"
        echo -e "Compressed file: ${GREEN}${BACKUP_FILE}.gz${NC}"
        COMPRESSED_SIZE=$(du -h "${BACKUP_FILE}.gz" | cut -f1)
        echo -e "Compressed size: ${GREEN}$COMPRESSED_SIZE${NC}"
    else
        echo -e "${YELLOW}Warning: Could not compress backup file${NC}"
    fi
else
    echo -e "${RED}✗ Backup failed!${NC}"
    exit 1
fi

echo "========================================"
echo -e "${GREEN}Backup process completed!${NC}"
