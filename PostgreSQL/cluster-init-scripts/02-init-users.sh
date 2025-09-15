#!/bin/bash
set -e

# This script runs during PostgreSQL initialization for cluster setup

echo "Creating additional users and databases for cluster..."

# Create application user
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Create application user
    CREATE USER appuser WITH PASSWORD 'appuser123';
    
    -- Create test database
    CREATE DATABASE testdb OWNER appuser;
    
    -- Grant privileges
    GRANT ALL PRIVILEGES ON DATABASE testdb TO appuser;
    GRANT ALL PRIVILEGES ON DATABASE $POSTGRES_DB TO appuser;
    
    -- Create read-only user for reports
    CREATE USER readonly WITH PASSWORD 'readonly123';
    GRANT CONNECT ON DATABASE $POSTGRES_DB TO readonly;
    GRANT CONNECT ON DATABASE testdb TO readonly;
    GRANT USAGE ON SCHEMA public TO readonly;
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO readonly;
EOSQL

echo "PostgreSQL cluster initialization completed successfully!"
