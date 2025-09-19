#!/bin/bash

# Load environment variables
if [ -f "../.env" ]; then
    export $(cat ../.env | grep -v '^#' | xargs)
fi

# Set the backup file name with a timestamp
BACKUP_FILE="pgvector_backup_$(date +'%Y%m%d_%H%M%S').sql"

# Set the database credentials from environment variables
DB_NAME=${DB_NAME:-pgvector_db}
DB_USER=${DB_USER:-pgvector_user}
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-5432}

echo "Creating backup of database '$DB_NAME' as user '$DB_USER'..."

# Change to parent directory to access docker-compose.yml
cd "$(dirname "$0")/.." || exit 1

# Perform the backup using pg_dump via docker compose
docker compose exec -T postgres pg_dump -U "$DB_USER" -d "$DB_NAME" > "scripts/$BACKUP_FILE"

# Check if the backup was successful
if [ $? -eq 0 ]; then
    echo "Backup successful! File: scripts/$BACKUP_FILE"
    ls -lh "scripts/$BACKUP_FILE"
else
    echo "Backup failed!"
    exit 1
fi