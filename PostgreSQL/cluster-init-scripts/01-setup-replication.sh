#!/bin/bash
set -e

# This script sets up replication users and configuration for the primary node

echo "Setting up replication for primary node..."

# Create replication user
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Create replication user
    CREATE USER $POSTGRES_REPLICATION_USER WITH REPLICATION PASSWORD '$POSTGRES_REPLICATION_PASSWORD';
    
    -- Grant necessary privileges
    GRANT CONNECT ON DATABASE $POSTGRES_DB TO $POSTGRES_REPLICATION_USER;
EOSQL

# Update pg_hba.conf for replication
echo "# Replication connections" >> /var/lib/postgresql/data/pg_hba.conf
echo "host replication $POSTGRES_REPLICATION_USER 0.0.0.0/0 md5" >> /var/lib/postgresql/data/pg_hba.conf
echo "host replication $POSTGRES_REPLICATION_USER ::/0 md5" >> /var/lib/postgresql/data/pg_hba.conf

# Allow connections from replicas
echo "host all all 0.0.0.0/0 md5" >> /var/lib/postgresql/data/pg_hba.conf

echo "Primary node replication setup completed!"
