#!/bin/bash
set -e

# This script runs during PostgreSQL initialization

echo "Creating additional users and databases..."

# Create application user
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Create application user
    CREATE USER appuser WITH PASSWORD 'appuser123';
    
    -- Create test database
    CREATE DATABASE testdb OWNER appuser;
    
    -- Grant privileges
    GRANT ALL PRIVILEGES ON DATABASE testdb TO appuser;
    GRANT ALL PRIVILEGES ON DATABASE $POSTGRES_DB TO appuser;
EOSQL

echo "PostgreSQL initialization completed successfully!"
