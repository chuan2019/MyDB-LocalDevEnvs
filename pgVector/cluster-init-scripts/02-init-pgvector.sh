#!/bin/bash

# This script initializes the pgvector extension on the replica PostgreSQL instance.

set -e

# Wait for PostgreSQL to be ready
until psql -h "$POSTGRES_HOST" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c '\q'; do
  echo "Waiting for PostgreSQL to be ready..."
  sleep 2
done

# Initialize pgvector extension
psql -h "$POSTGRES_HOST" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "CREATE EXTENSION IF NOT EXISTS vector;" 

echo "pgvector extension initialized successfully."