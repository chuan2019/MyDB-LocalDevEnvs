#!/bin/bash

# MongoDB Restore Script
# This script restores MongoDB databases from backup

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

# Check if backup path is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: Backup path not provided${NC}"
    echo -e "${YELLOW}Usage: $0 <backup_path>${NC}"
    echo -e "${YELLOW}Example: $0 ./backups/mongodb_backup_20241214_120000.tar.gz${NC}"
    echo
    echo -e "${BLUE}Available backups:${NC}"
    ls -la ./backups/mongodb_backup_*.tar.gz 2>/dev/null || echo "No backups found"
    exit 1
fi

BACKUP_PATH="$1"

# Check if backup file exists
if [ ! -f "${BACKUP_PATH}" ]; then
    echo -e "${RED}Error: Backup file not found: ${BACKUP_PATH}${NC}"
    exit 1
fi

echo -e "${BLUE}Starting MongoDB restore...${NC}"
echo -e "${YELLOW}Restoring from: ${BACKUP_PATH}${NC}"

# Determine which container to use for restore
if docker ps --format "table {{.Names}}" | grep -q "mongodb_primary"; then
    CONTAINER_NAME="mongodb_primary"
    echo -e "${BLUE}Using replica set primary for restore${NC}"
elif docker ps --format "table {{.Names}}" | grep -q "mongodb_single"; then
    CONTAINER_NAME="mongodb_single"
    echo -e "${BLUE}Using single node for restore${NC}"
else
    echo -e "${RED}No MongoDB container found running${NC}"
    exit 1
fi

# Extract backup filename without extension
BACKUP_FILENAME=$(basename "${BACKUP_PATH}" .tar.gz)
TEMP_DIR="/tmp/restore_${BACKUP_FILENAME}"

# Extract backup
echo -e "${BLUE}Extracting backup...${NC}"
mkdir -p "${TEMP_DIR}"
tar -xzf "${BACKUP_PATH}" -C "${TEMP_DIR}"

# Copy extracted backup to container
echo -e "${BLUE}Copying backup to container...${NC}"
docker cp "${TEMP_DIR}/${BACKUP_FILENAME}" "${CONTAINER_NAME}:/tmp/"

# Perform restore
echo -e "${YELLOW}WARNING: This will overwrite existing data!${NC}"
read -p "Are you sure you want to continue? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Restore cancelled${NC}"
    rm -rf "${TEMP_DIR}"
    exit 0
fi

echo -e "${BLUE}Performing database restore...${NC}"
docker exec "${CONTAINER_NAME}" mongorestore \
    --username "${MONGO_INITDB_ROOT_USERNAME}" \
    --password "${MONGO_INITDB_ROOT_PASSWORD}" \
    --authenticationDatabase admin \
    --drop \
    "/tmp/${BACKUP_FILENAME}"

# Cleanup
echo -e "${BLUE}Cleaning up temporary files...${NC}"
rm -rf "${TEMP_DIR}"
docker exec "${CONTAINER_NAME}" rm -rf "/tmp/${BACKUP_FILENAME}"

echo -e "${GREEN}Restore completed successfully!${NC}"

# Verify restore by listing databases
echo -e "${BLUE}Verifying restore - Available databases:${NC}"
docker exec "${CONTAINER_NAME}" mongosh \
    --username "${MONGO_INITDB_ROOT_USERNAME}" \
    --password "${MONGO_INITDB_ROOT_PASSWORD}" \
    --authenticationDatabase admin \
    --eval "db.adminCommand('listDatabases')"

echo -e "${GREEN}Restore process completed!${NC}"
