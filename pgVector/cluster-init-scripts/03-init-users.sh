#!/bin/bash

# Create necessary users and roles on the replica instance
psql -U postgres -d your_database_name -f /docker-entrypoint-initdb.d/init-scripts/02-init-users.sql