#!/bin/bash

# Load environment variables
if [ -f "../.env" ]; then
    export $(cat ../.env | grep -v '^#' | xargs)
fi

# Monitor the health and status of the PostgreSQL instances

# Define the PostgreSQL connection parameters
PG_HOST=${DB_HOST:-localhost}
PG_PORT=${DB_PORT:-5432}
DB_NAME=${DB_NAME:-pgvector_db}
DB_USER=${DB_USER:-pgvector_user}

# Set PGPASSWORD for non-interactive authentication
export PGPASSWORD="${DB_PASSWORD}"

echo "Starting PostgreSQL monitoring..."
echo "Host: $PG_HOST, Port: $PG_PORT, Database: $DB_NAME, User: $DB_USER"
echo "Press Ctrl+C to stop monitoring"
echo "----------------------------------------"

# Function to check the status of PostgreSQL
check_postgres() {
    cd "$(dirname "$0")/.." || exit 1
    docker compose exec -T postgres pg_isready -U "$DB_USER" > /dev/null 2>&1
    return $?
}

# Function to get database stats
get_db_stats() {
    cd "$(dirname "$0")/.." || exit 1
    docker compose exec -T postgres psql -U "$DB_USER" -d "$DB_NAME" -t -c "
        SELECT 
            'Connections: ' || count(*) 
        FROM pg_stat_activity 
        WHERE datname = '$DB_NAME';
    " 2>/dev/null | tr -d '[:space:]'
}

# Main monitoring loop
while true; do
    # Change to the parent directory for docker-compose
    cd "$(dirname "$0")/.." || exit 1
    
    if docker compose exec -T postgres pg_isready -U "$DB_USER" > /dev/null 2>&1; then
        stats=$(docker compose exec -T postgres psql -U "$DB_USER" -d "$DB_NAME" -t -c "
            SELECT 
                'Connections: ' || count(*) 
            FROM pg_stat_activity 
            WHERE datname = '$DB_NAME';
        " 2>/dev/null | tr -d '[:space:]')
        echo "$(date '+%Y-%m-%d %H:%M:%S'): PostgreSQL is running. $stats"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S'): PostgreSQL is down or unreachable!"
        # You can add additional actions here, such as sending alerts or restarting the service
    fi
    sleep 30  # Check every 30 seconds
done