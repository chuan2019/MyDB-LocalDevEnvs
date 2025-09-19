#!/bin/bash

# This script sets up replication between the primary and replica PostgreSQL instances.

set -e

# Variables
PRIMARY_HOST="primary"
REPLICA_HOST="replica"
REPLICA_USER="replication_user"
REPLICA_PASSWORD="replication_password"
DATABASE_NAME="your_database_name"

# Create replication user on primary
psql -h $PRIMARY_HOST -U postgres -c "CREATE ROLE $REPLICA_USER WITH REPLICATION LOGIN PASSWORD '$REPLICA_PASSWORD';"

# Configure primary for replication
echo "host    replication     $REPLICA_USER     $REPLICA_HOST/32     md5" >> /var/lib/postgresql/data/pg_hba.conf
echo "wal_level = replica" >> /var/lib/postgresql/data/postgresql.conf
echo "max_wal_senders = 3" >> /var/lib/postgresql/data/postgresql.conf
echo "wal_keep_segments = 64" >> /var/lib/postgresql/data/postgresql.conf

# Restart primary to apply changes
pg_ctl -D /var/lib/postgresql/data restart

# Set up the replica
pg_basebackup -h $PRIMARY_HOST -D /var/lib/postgresql/data -U $REPLICA_USER -P --wal-method=stream

# Create recovery.conf on the replica
cat <<EOL > /var/lib/postgresql/data/recovery.conf
standby_mode = 'on'
primary_conninfo = 'host=$PRIMARY_HOST port=5432 user=$REPLICA_USER password=$REPLICA_PASSWORD'
trigger_file = '/tmp/postgresql.trigger.5432'
EOL

# Restart the replica
pg_ctl -D /var/lib/postgresql/data restart

echo "Replication setup completed."