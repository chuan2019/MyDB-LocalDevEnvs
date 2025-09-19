#!/bin/bash

# Load environment variables
if [ -f "../.env" ]; then
    export $(cat ../.env | grep -v '^#' | xargs)
fi

# Check if the backup file is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <backup_file>"
    echo "Example: $0 pgvector_backup_20231201_143022.sql"
    exit 1
fi

BACKUP_FILE=$1

# Check if the backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
    echo "Backup file $BACKUP_FILE does not exist."
    exit 1
fi

# Set database credentials from environment variables
DB_NAME=${DB_NAME:-pgvector_db}
DB_USER=${DB_USER:-pgvector_user}
CONTAINER_NAME=${CONTAINER_NAME:-pgvector_db}

echo "Restoring database '$DB_NAME' from $BACKUP_FILE..."
echo "Container: $CONTAINER_NAME, User: $DB_USER"

# Restore the database from the backup file
if docker ps --format 'table {{.Names}}' | grep -q "$CONTAINER_NAME"; then
    docker exec -i "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" < "$BACKUP_FILE"
    if [ $? -eq 0 ]; then
        echo "Database restored successfully from $BACKUP_FILE"
    else
        echo "Database restore failed!"
        exit 1
    fi
else
    echo "Error: Container '$CONTAINER_NAME' is not running."
    echo "Please start the container first with: docker compose up -d"
    exit 1
fi