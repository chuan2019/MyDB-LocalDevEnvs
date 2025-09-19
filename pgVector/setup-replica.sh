#!/bin/bash

# This script sets up the replication configuration for the PostgreSQL database.

# Load environment variables from .env file
if [ -f .env ]; then
    export $(cat .env | xargs)
fi

# Check if the primary database is reachable
if ! pg_isready -h $PRIMARY_HOST -p $PRIMARY_PORT -U $PRIMARY_USER; then
    echo "Primary database is not reachable. Exiting."
    exit 1
fi

# Set up replication user on the primary database
psql -h $PRIMARY_HOST -p $PRIMARY_PORT -U $PRIMARY_USER -c "CREATE ROLE $REPLICA_USER WITH REPLICATION PASSWORD '$REPLICA_PASSWORD' LOGIN;"

# Get the primary's current WAL file and position
WAL_INFO=$(psql -h $PRIMARY_HOST -p $PRIMARY_PORT -U $PRIMARY_USER -c "SELECT pg_current_wal_lsn();" -t)
echo "Current WAL position on primary: $WAL_INFO"

# Configure the replica to connect to the primary
echo "Setting up recovery configuration on the replica..."
cat <<EOL > /var/lib/postgresql/data/recovery.conf
standby_mode = 'on'
primary_conninfo = 'host=$PRIMARY_HOST port=$PRIMARY_PORT user=$REPLICA_USER password=$REPLICA_PASSWORD'
trigger_file = '/tmp/postgresql.trigger.5432'
EOL

# Restart the PostgreSQL service to apply changes
echo "Restarting PostgreSQL service..."
service postgresql restart

echo "Replication setup completed."