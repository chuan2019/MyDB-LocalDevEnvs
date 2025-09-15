#!/bin/bash

# PostgreSQL Cluster Monitor Script
# Usage: ./monitor.sh [mode]
# Modes: health, replication, performance, all

set -e

MODE="${1:-all}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_subheader() {
    echo -e "\n${YELLOW}--- $1 ---${NC}"
}

check_container_status() {
    print_header "Container Status"
    
    echo "Docker Compose Services:"
    if docker-compose -f docker-compose-cluster.yml ps 2>/dev/null; then
        echo ""
    else
        echo -e "${RED}Error: Cluster not running. Use 'docker-compose -f docker-compose-cluster.yml up -d' to start.${NC}"
        return 1
    fi
    
    echo "Container Health:"
    for container in postgres_primary postgres_replica_1 postgres_replica_2 postgres_loadbalancer pgadmin_cluster; do
        if docker ps | grep -q "$container"; then
            status=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "no-healthcheck")
            if [ "$status" = "healthy" ]; then
                echo -e "  $container: ${GREEN}✓ Healthy${NC}"
            elif [ "$status" = "no-healthcheck" ]; then
                echo -e "  $container: ${YELLOW}⚠ Running (no healthcheck)${NC}"
            else
                echo -e "  $container: ${RED}✗ Unhealthy${NC}"
            fi
        else
            echo -e "  $container: ${RED}✗ Not running${NC}"
        fi
    done
}

check_postgres_health() {
    print_header "PostgreSQL Health Check"
    
    print_subheader "Primary Node"
    if docker exec postgres_primary pg_isready -U postgres >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Primary is ready${NC}"
        
        # Get version and uptime
        version=$(docker exec postgres_primary psql -U postgres -t -c "SELECT version();" | head -1 | xargs)
        uptime=$(docker exec postgres_primary psql -U postgres -t -c "SELECT NOW() - pg_postmaster_start_time() AS uptime;" | xargs)
        echo "  Version: $version"
        echo "  Uptime: $uptime"
    else
        echo -e "${RED}✗ Primary is not ready${NC}"
        return 1
    fi
    
    print_subheader "Replica Nodes"
    for replica in postgres_replica_1 postgres_replica_2; do
        if docker exec "$replica" pg_isready -U postgres >/dev/null 2>&1; then
            echo -e "${GREEN}✓ $replica is ready${NC}"
            
            # Check if in recovery mode
            recovery=$(docker exec "$replica" psql -U postgres -t -c "SELECT pg_is_in_recovery();" | xargs)
            if [ "$recovery" = "t" ]; then
                echo -e "  ${GREEN}✓ In recovery mode (replica)${NC}"
            else
                echo -e "  ${RED}✗ Not in recovery mode${NC}"
            fi
        else
            echo -e "${RED}✗ $replica is not ready${NC}"
        fi
    done
}

check_replication_status() {
    print_header "Replication Status"
    
    print_subheader "Primary - Active Replicas"
    docker exec postgres_primary psql -U postgres -c "
    SELECT 
        client_addr,
        application_name,
        state,
        sync_state,
        write_lag,
        flush_lag,
        replay_lag
    FROM pg_stat_replication;
    " || echo -e "${RED}Error checking replication status${NC}"
    
    print_subheader "Replica Lag Information"
    docker exec postgres_primary psql -U postgres -c "
    SELECT 
        client_addr,
        CASE 
            WHEN write_lag IS NULL THEN 'N/A'
            ELSE write_lag::text
        END as write_lag,
        CASE 
            WHEN flush_lag IS NULL THEN 'N/A'
            ELSE flush_lag::text
        END as flush_lag,
        CASE 
            WHEN replay_lag IS NULL THEN 'N/A'
            ELSE replay_lag::text
        END as replay_lag
    FROM pg_stat_replication;
    " || echo -e "${RED}Error checking replication lag${NC}"
    
    print_subheader "WAL Status"
    docker exec postgres_primary psql -U postgres -c "
    SELECT 
        pg_current_wal_lsn() as current_wal_lsn,
        pg_wal_lsn_diff(pg_current_wal_lsn(), '0/0') / 1024 / 1024 as wal_mb;
    " || echo -e "${RED}Error checking WAL status${NC}"
}

check_performance() {
    print_header "Performance Metrics"
    
    print_subheader "Connection Counts"
    for node in postgres_primary postgres_replica_1 postgres_replica_2; do
        echo "=== $node ==="
        docker exec "$node" psql -U postgres -c "
        SELECT 
            datname,
            count(*) as connections,
            max(state) as max_state
        FROM pg_stat_activity 
        WHERE datname IS NOT NULL 
        GROUP BY datname
        ORDER BY connections DESC;
        " 2>/dev/null || echo "  Cannot connect to $node"
    done
    
    print_subheader "Database Sizes"
    docker exec postgres_primary psql -U postgres -c "
    SELECT 
        datname,
        pg_size_pretty(pg_database_size(datname)) as size
    FROM pg_database 
    WHERE datistemplate = false
    ORDER BY pg_database_size(datname) DESC;
    " || echo -e "${RED}Error checking database sizes${NC}"
    
    print_subheader "Top Tables by Size"
    docker exec postgres_primary psql -U postgres -d devdb -c "
    SELECT 
        schemaname,
        tablename,
        pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
    FROM pg_tables 
    WHERE schemaname = 'public'
    ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
    LIMIT 10;
    " 2>/dev/null || echo "  No devdb database found"
}

check_haproxy_status() {
    print_header "HAProxy Load Balancer Status"
    
    if docker ps | grep -q postgres_loadbalancer; then
        echo -e "${GREEN}✓ HAProxy is running${NC}"
        echo "Stats URL: http://localhost:8404/stats"
        
        # Try to get stats via curl if available
        if command -v curl >/dev/null 2>&1; then
            print_subheader "Backend Status"
            curl -s "http://localhost:8404/stats;csv" | grep -E "(postgres_primary|postgres_replicas)" | while IFS=',' read -r pxname svname qcur qmax scur smax slim stot bin bout dreq dresp ereq econ eresp wretr wredis status weight act bck chkfail chkdown lastchg downtime qlimit pid iid sid throttle lbtot tracked type rate rate_lim rate_max check_status check_code check_duration hrsp_1xx hrsp_2xx hrsp_3xx hrsp_4xx hrsp_5xx hrsp_other hanafail req_rate req_rate_max req_tot cli_abrt srv_abrt comp_in comp_out comp_byp comp_rsp lastsess last_chk last_agt qtime ctime rtime ttime agent_status agent_code agent_duration check_desc agent_desc check_rise check_fall check_health agent_rise agent_fall agent_health addr cookie mode algo src_port proto; do
                if [ "$svname" != "BACKEND" ] && [ "$svname" != "FRONTEND" ]; then
                    case "$status" in
                        "UP") echo -e "  $pxname/$svname: ${GREEN}UP${NC}" ;;
                        "DOWN") echo -e "  $pxname/$svname: ${RED}DOWN${NC}" ;;
                        *) echo -e "  $pxname/$svname: ${YELLOW}$status${NC}" ;;
                    esac
                fi
            done 2>/dev/null || echo "  Could not retrieve HAProxy stats"
        else
            echo "  Install curl to see detailed HAProxy status"
        fi
    else
        echo -e "${RED}✗ HAProxy is not running${NC}"
    fi
}

# Main execution
case "$MODE" in
    "health")
        check_container_status
        check_postgres_health
        ;;
    "replication")
        check_replication_status
        ;;
    "performance")
        check_performance
        ;;
    "haproxy")
        check_haproxy_status
        ;;
    "all")
        check_container_status
        check_postgres_health
        check_replication_status
        check_performance
        check_haproxy_status
        ;;
    *)
        echo "Usage: $0 [health|replication|performance|haproxy|all]"
        echo "  health      - Check container and PostgreSQL health"
        echo "  replication - Check replication status and lag"
        echo "  performance - Show performance metrics"
        echo "  haproxy     - Check load balancer status"
        echo "  all         - Run all checks (default)"
        exit 1
        ;;
esac

print_header "Monitor Complete"
echo -e "Run ${GREEN}'./monitor.sh help'${NC} for usage options"
