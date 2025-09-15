#!/bin/bash

# MongoDB Backup Script
# This script creates backups of MongoDB databases

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
BACKUP_RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-7}

# Configuration
BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="mongodb_backup_${TIMESTAMP}"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"

# Create backup directory if it doesn't exist
mkdir -p "${BACKUP_DIR}"

echo -e "${BLUE}Starting MongoDB backup...${NC}"
echo -e "${YELLOW}Backup will be saved to: ${BACKUP_PATH}${NC}"

# Determine which container to use for backup
if docker ps --format "table {{.Names}}" | grep -q "mongodb_primary"; then
    CONTAINER_NAME="mongodb_primary"
    echo -e "${BLUE}Using replica set primary for backup${NC}"
elif docker ps --format "table {{.Names}}" | grep -q "mongodb_single"; then
    CONTAINER_NAME="mongodb_single"
    echo -e "${BLUE}Using single node for backup${NC}"
else
    echo -e "${RED}No MongoDB container found running${NC}"
    exit 1
fi

# Create backup using mongodump
echo -e "${BLUE}Creating database dump...${NC}"
docker exec "${CONTAINER_NAME}" mongodump \
    --username "${MONGO_INITDB_ROOT_USERNAME}" \
    --password "${MONGO_INITDB_ROOT_PASSWORD}" \
    --authenticationDatabase admin \
    --out "/tmp/${BACKUP_NAME}"

# Copy backup from container to host
echo -e "${BLUE}Copying backup to host...${NC}"
docker cp "${CONTAINER_NAME}:/tmp/${BACKUP_NAME}" "${BACKUP_PATH}"

# Compress backup
echo -e "${BLUE}Compressing backup...${NC}"
ORIGINAL_DIR=$(pwd)
cd "${BACKUP_DIR}"
tar -czf "${BACKUP_NAME}.tar.gz" "${BACKUP_NAME}"
rm -rf "${BACKUP_NAME}"
cd "${ORIGINAL_DIR}"

# Cleanup old backups
echo -e "${BLUE}Cleaning up old backups (older than ${BACKUP_RETENTION_DAYS} days)...${NC}"
find "${BACKUP_DIR}" -name "mongodb_backup_*.tar.gz" -type f -mtime +${BACKUP_RETENTION_DAYS} -delete 2>/dev/null || true

# Display backup information
BACKUP_SIZE=$(du -h "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" | cut -f1)
echo -e "${GREEN}Backup completed successfully!${NC}"
echo -e "${BLUE}Backup file: ${BACKUP_NAME}.tar.gz${NC}"
echo -e "${BLUE}Backup size: ${BACKUP_SIZE}${NC}"
echo -e "${BLUE}Backup location: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz${NC}"

# List available backups
echo -e "${YELLOW}Available backups:${NC}"
if ls "${BACKUP_DIR}"/mongodb_backup_*.tar.gz 1> /dev/null 2>&1; then
    ls -lah "${BACKUP_DIR}"/mongodb_backup_*.tar.gz
else
    echo "No backups found"
fi

echo -e "${GREEN}Backup process completed!${NC}"
