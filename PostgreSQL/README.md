# PostgreSQL Local Development Enviro### Manual Docker Compose

#### Single Node Setup

1. **Clone and navigate to the directory:**
   ```bash
   cd /path/to/PostgreSQL/local-dev
   ```

2. **Start the single node setup:**
   ```bash
   docker-compose up -d
   ```

3. **Access the services:**
   - PostgreSQL: `localhost:5432`
   - pgAdmin: `http://localhost:8080`

#### Cluster Setupitory provides Docker Compose configurations for running PostgreSQL in local development and testing environments. It includes both single-node and cluster setups with proper monitoring and administration tools.

## Quick Start

### Prerequisites

- Docker (version 20.10 or later)
- Docker Compose (version 2.0 or later)
- GNU Make (optional, for easier operations)
- Git

### Using Make (Recommended)

This project includes a comprehensive Makefile for easy operations:

```bash
# See all available commands
make help

# Quick development start (single node)
make dev

# Quick production-like testing (cluster)
make prod-test

# Check status
make status

# Create backup
make backup

# Monitor cluster
make monitor
```

### Manual Docker Compose

1. **Clone and navigate to the directory:**
   ```bash
   cd /path/to/PostgreSQL/local-dev
   ```

2. **Start the single node setup:**
   ```bash
   docker-compose up -d
   ```

3. **Access the services:**
   - PostgreSQL: `localhost:5432`
   - pgAdmin: `http://localhost:8080`

### Cluster Setup

1. **Start the cluster setup:**
   ```bash
   docker-compose -f docker-compose-cluster.yml up -d
   ```

2. **Access the services:**
   - Primary: `localhost:5432`
   - Replica 1: `localhost:5433`
   - Replica 2: `localhost:5434`
   - Load Balancer (Write): `localhost:5430`
   - Load Balancer (Read): `localhost:5431`
   - HAProxy Stats: `http://localhost:8404/stats`
   - pgAdmin: `http://localhost:8080`

## Project Structure

```
local-dev/
├── Makefile                       # GNU Make commands for operations
├── docker-compose.yml              # Single node configuration
├── docker-compose-cluster.yml     # Cluster configuration
├── .env                           # Environment variables
├── .env.example                   # Example environment file
├── postgresql.conf                # Single node PostgreSQL config
├── postgresql-primary.conf        # Primary node config
├── postgresql-replica.conf        # Replica node config
├── haproxy.cfg                    # Load balancer configuration
├── pgadmin-servers.json           # pgAdmin server definitions (single)
├── pgadmin-cluster-servers.json   # pgAdmin server definitions (cluster)
├── setup-replica.sh              # Replica setup script
├── init-scripts/                  # Single node initialization
│   ├── 01-init-users.sh
│   └── 02-sample-data.sql
├── cluster-init-scripts/          # Cluster initialization
│   ├── 01-setup-replication.sh
│   ├── 02-init-users.sh
│   └── 03-sample-data.sql
└── scripts/                       # Utility scripts
    ├── backup.sh
    ├── restore.sh
    ├── monitor.sh
    └── test-replication.sh
```

## Configuration

### Environment Variables

The `.env` file contains all configurable parameters:

```bash
# PostgreSQL Configuration
POSTGRES_DB=devdb
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres123

# Ports
POSTGRES_PORT=5432
POSTGRES_PRIMARY_PORT=5432
POSTGRES_REPLICA1_PORT=5433
POSTGRES_REPLICA2_PORT=5434

# Replication
POSTGRES_REPLICATION_USER=replicator
POSTGRES_REPLICATION_PASSWORD=replicator123

# Load Balancer
POSTGRES_LB_WRITE_PORT=5430
POSTGRES_LB_READ_PORT=5431
HAPROXY_STATS_PORT=8404

# pgAdmin
PGADMIN_EMAIL=admin@localhost.com
PGADMIN_PASSWORD=admin123
PGADMIN_PORT=8080
```

### PostgreSQL Configuration

- **Single Node**: Uses `postgresql.conf` with basic development settings
- **Primary Node**: Uses `postgresql-primary.conf` with replication enabled
- **Replica Nodes**: Uses `postgresql-replica.conf` with standby settings

Key features enabled:
- Statement logging for debugging
- Performance optimization for development
- Replication configuration (cluster mode)
- Connection logging and monitoring

## Connection Examples

### Single Node Connections

```bash
# Using psql
psql -h localhost -p 5432 -U postgres -d devdb

# Connection string
postgresql://postgres:postgres123@localhost:5432/devdb
```

### Cluster Connections

```bash
# Direct connections
psql -h localhost -p 5432 -U postgres -d devdb  # Primary
psql -h localhost -p 5433 -U postgres -d devdb  # Replica 1
psql -h localhost -p 5434 -U postgres -d devdb  # Replica 2

# Load balanced connections
psql -h localhost -p 5430 -U postgres -d devdb  # Write (Primary)
psql -h localhost -p 5431 -U postgres -d devdb  # Read (Replicas)
```

### Application Connection Examples

#### Python (psycopg2)
```python
import psycopg2

# Single node
conn = psycopg2.connect(
    host="localhost",
    port=5432,
    database="devdb",
    user="postgres",
    password="postgres123"
)

# Cluster - write operations
write_conn = psycopg2.connect(
    host="localhost",
    port=5430,  # Load balancer write port
    database="devdb",
    user="postgres",
    password="postgres123"
)

# Cluster - read operations
read_conn = psycopg2.connect(
    host="localhost",
    port=5431,  # Load balancer read port
    database="devdb",
    user="postgres",
    password="postgres123"
)
```

#### Node.js (pg)
```javascript
const { Pool } = require('pg');

// Single node
const pool = new Pool({
  host: 'localhost',
  port: 5432,
  database: 'devdb',
  user: 'postgres',
  password: 'postgres123',
});

// Cluster - separate pools for read/write
const writePool = new Pool({
  host: 'localhost',
  port: 5430,  // Load balancer write port
  database: 'devdb',
  user: 'postgres',
  password: 'postgres123',
});

const readPool = new Pool({
  host: 'localhost',
  port: 5431,  // Load balancer read port
  database: 'devdb',
  user: 'postgres',
  password: 'postgres123',
});
```

## Management Commands

### Using Make (Recommended)

The Makefile provides convenient commands for all operations:

```bash
# Development workflow
make dev                    # Start single node for development
make connect-single         # Connect to database
make backup                 # Create backup
make single-down           # Stop when done

# Production testing workflow  
make prod-test             # Start cluster
make test-replication      # Test replication
make monitor              # Monitor cluster health
make cluster-down         # Stop cluster

# Connection commands
make connect-primary       # Connect to primary
make connect-replica1      # Connect to replica 1  
make connect-lb-write     # Connect via load balancer (writes)
make connect-lb-read      # Connect via load balancer (reads)

# Monitoring commands
make status               # Show service status
make logs                # Show logs (interactive)
make logs-primary        # Show primary logs
make monitor-health      # Health check only
make monitor-replication # Replication status only

# Backup/restore commands
make backup              # Interactive backup
make backup-single       # Backup single node
make backup-primary      # Backup primary node
make restore             # Interactive restore
make list-backups        # List available backups
make quick-backup        # Quick timestamped backup

# Testing commands
make test-replication    # Test replication functionality
make test-connections    # Test all connections
make performance-test    # Basic performance test

# Maintenance commands
make setup              # Initial setup
make pull               # Pull latest images
make volumes-clean      # Clean volumes (DATA LOSS!)
make full-clean        # Complete cleanup

# Web interfaces
make pgadmin           # Open pgAdmin in browser
make haproxy-stats     # Open HAProxy stats in browser

# Information
make help              # Show all commands
make info              # Show system information
make health-check      # Quick health check
```

### Manual Docker Compose Commands

### Manual Docker Compose Commands

#### Basic Operations

```bash
# Start services
docker-compose up -d                              # Single node
docker-compose -f docker-compose-cluster.yml up -d # Cluster

# Stop services
docker-compose down                               # Single node
docker-compose -f docker-compose-cluster.yml down # Cluster

# View logs
docker-compose logs postgres                      # Single node logs
docker-compose logs postgres-primary              # Primary logs
docker-compose logs postgres-replica-1            # Replica 1 logs

# Check service status
docker-compose ps                                 # Single node
docker-compose -f docker-compose-cluster.yml ps  # Cluster
```

#### Database Operations

```bash
# Execute SQL commands
docker-compose exec postgres psql -U postgres -d devdb -c "SELECT version();"

# Connect to database shell
docker-compose exec postgres psql -U postgres -d devdb

# Check replication status (cluster)
docker-compose exec postgres-primary psql -U postgres -c "SELECT * FROM pg_stat_replication;"
```

#### Utility Scripts (Alternative to Make)

```bash
# Backup database
./scripts/backup.sh

# Restore database
./scripts/restore.sh backup_file.sql

# Monitor cluster health
./scripts/monitor.sh

# Test replication
./scripts/test-replication.sh
```

## Monitoring and Administration

### pgAdmin Access

1. **Open pgAdmin**: `http://localhost:8080`
2. **Login credentials**:
   - Email: `admin@localhost.com`
   - Password: `admin123`
3. **Pre-configured servers** will be available based on your setup

### HAProxy Statistics (Cluster Mode)

1. **Open HAProxy Stats**: `http://localhost:8404/stats`
2. **Monitor**:
   - Connection counts
   - Server health status
   - Load balancing distribution
   - Response times

### Health Checks

```bash
# Check PostgreSQL status
docker-compose exec postgres pg_isready -U postgres

# Check replication lag (cluster)
docker-compose exec postgres-primary psql -U postgres -c "
  SELECT client_addr, state, sent_lsn, write_lsn, 
         flush_lsn, replay_lsn, write_lag, flush_lag, replay_lag 
  FROM pg_stat_replication;"

# Check if replica is in recovery mode
docker-compose exec postgres-replica-1 psql -U postgres -c "SELECT pg_is_in_recovery();"
```

## Troubleshooting

### Common Issues

#### 1. Port Already in Use
```bash
# Check what's using the port
sudo netstat -tulpn | grep :5432

# Kill the process or change ports in .env file
```

#### 2. Replica Not Connecting to Primary
```bash
# Check primary logs
docker-compose logs postgres-primary

# Check replica logs
docker-compose logs postgres-replica-1

# Verify replication user exists
docker-compose exec postgres-primary psql -U postgres -c "\du"
```

#### 3. Permission Denied Errors
```bash
# Fix script permissions
chmod +x scripts/*.sh
chmod +x init-scripts/*.sh
chmod +x cluster-init-scripts/*.sh
```

#### 4. Data Directory Issues
```bash
# Clean up and restart (WARNING: This will delete all data)
docker-compose down -v
docker-compose up -d
```

### Logs and Debugging

```bash
# View all logs
docker-compose logs

# Follow logs in real-time
docker-compose logs -f postgres

# View specific service logs
docker-compose logs postgres-primary
docker-compose logs haproxy
docker-compose logs pgadmin
```

## Advanced Usage

### Custom Initialization

Add your own SQL files to the appropriate init-scripts directory:
- Single node: `init-scripts/`
- Cluster: `cluster-init-scripts/`

Files are executed in alphabetical order during container initialization.

### Performance Testing

```bash
# Install pgbench (if not available)
sudo apt-get install postgresql-client

# Initialize pgbench
pgbench -i -h localhost -p 5432 -U postgres devdb

# Run performance test
pgbench -c 10 -j 2 -t 1000 -h localhost -p 5432 -U postgres devdb
```

### Backup and Restore

```bash
# Manual backup
pg_dump -h localhost -p 5432 -U postgres devdb > backup.sql

# Manual restore
psql -h localhost -p 5432 -U postgres devdb < backup.sql

# Using Docker
docker-compose exec postgres pg_dump -U postgres devdb > backup.sql
docker-compose exec -T postgres psql -U postgres devdb < backup.sql
```

## Security Considerations

### For Development Use Only

This setup is designed for local development and testing. **DO NOT** use in production without:

1. **Changing default passwords**
2. **Enabling SSL/TLS**
3. **Configuring proper firewall rules**
4. **Setting up proper authentication methods**
5. **Implementing backup strategies**
6. **Securing network access**

### Production Checklist

- [ ] Change all default passwords
- [ ] Enable SSL certificates
- [ ] Configure pg_hba.conf properly
- [ ] Set up monitoring and alerting
- [ ] Implement backup and recovery procedures
- [ ] Configure log rotation
- [ ] Set resource limits
- [ ] Enable audit logging

## Sample Data

Both setups include sample data for testing:

- **Users table**: Sample user accounts
- **Posts table**: Blog posts with relationships
- **Tags table**: Post categorization
- **Analytics data**: Page views for testing read workloads

### Sample Queries

```sql
-- Get all published posts with authors
SELECT * FROM published_posts;

-- Get post analytics
SELECT * FROM post_analytics;

-- Test read-heavy function
SELECT * FROM get_popular_posts(5);

-- Check user activity
SELECT u.username, COUNT(p.id) as post_count
FROM users u
LEFT JOIN posts p ON u.id = p.user_id
GROUP BY u.username
ORDER BY post_count DESC;
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with both single and cluster modes
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Useful Links

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [pgAdmin Documentation](https://www.pgadmin.org/docs/)
- [HAProxy Documentation](http://www.haproxy.org/#docs)

---

**Happy coding!**
