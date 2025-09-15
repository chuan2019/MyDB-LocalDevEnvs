# MongoDB Local Development Environment

This directory provides Docker Compose configurations for running MongoDB in local development and testing environments. It includes both single-node and replica set cluster setups with proper monitoring and administration tools.

## Recent Updates (September 2025)

**All scripts have been thoroughly tested and validated!**

- **Fixed critical bugs** in replica set testing scripts
- **Enhanced backup/restore** functionality with better error handling  
- **Improved monitoring** with comprehensive dashboard
- **Added validation suite** for replica set functionality
- **Better output parsing** and user feedback in all scripts

**Test Status**: All management scripts pass comprehensive validation tests.

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

# Quick production-like testing (replica set cluster)
make prod-test

# Check status
make status

# Create backup
make backup

# Monitor cluster
make monitor

# Connect to primary
make connect-primary

# Connect to MongoDB Express (Web UI)
make mongo-express

# Clean everything
make clean
```

### Quick Validation

After starting your MongoDB setup, validate that everything is working:

```bash
# For replica set setup - comprehensive validation
./scripts/test-replica-set.sh

# Monitor your cluster
./scripts/monitor.sh

# Create a backup
./scripts/backup.sh

# Check container health
make status
```

### Manual Docker Compose

#### Single Node Setup

1. **Clone and navigate to the directory:**
   ```bash
   cd /path/to/MongoDB/local-dev
   ```

2. **Start the single node setup:**
   ```bash
   docker-compose up -d
   ```

3. **Access the services:**
   - MongoDB: `localhost:27017`
   - MongoDB Express: `http://localhost:8081`

#### Replica Set Cluster Setup

1. **Start the cluster:**
   ```bash
   docker-compose -f docker-compose-cluster.yml up -d
   ```

2. **Initialize the replica set:**
   ```bash
   ./scripts/init-replica-set.sh
   ```

3. **Access the services:**
   - MongoDB Primary: `localhost:27017`
   - MongoDB Secondary 1: `localhost:27018`
   - MongoDB Secondary 2: `localhost:27019`
   - MongoDB Express: `http://localhost:8081`

## Environment Configuration

Copy `.env.example` to `.env` and customize:

```bash
cp .env.example .env
```

### Default Credentials

- **MongoDB Admin User**: `admin`
- **MongoDB Admin Password**: `admin123`
- **MongoDB Express User**: `admin`
- **MongoDB Express Password**: `admin123`

### Default Ports

- **MongoDB Single**: 27017
- **MongoDB Primary**: 27017
- **MongoDB Secondary 1**: 27018
- **MongoDB Secondary 2**: 27019
- **MongoDB Express**: 8081

## Features

### Single Node Setup
- MongoDB 7.0 with authentication
- MongoDB Express for web-based administration
- Sample data initialization
- Persistent data volumes
- Health checks

### Replica Set Cluster Setup
- 3-node replica set (1 primary + 2 secondaries)
- Automatic failover
- Read scaling across secondaries
- MongoDB Express connected to replica set
- Monitoring and health checks
- Automated backup scripts

## Database Operations

### Connecting to MongoDB

```bash
# Single node
mongosh mongodb://admin:admin123@localhost:27017/admin

# Replica set
mongosh mongodb://admin:admin123@localhost:27017,localhost:27018,localhost:27019/admin?replicaSet=rs0
```

### Creating a Database and User

```javascript
// Connect to admin database
use admin

// Create application database
use myapp

// Create application user
db.createUser({
  user: "appuser",
  pwd: "apppass123",
  roles: [
    { role: "readWrite", db: "myapp" }
  ]
})
```

### Replica Set Management

```javascript
// Check replica set status
rs.status()

// Check replica set configuration
rs.conf()

// Add a new member (if needed)
rs.add("mongodb-secondary-3:27017")

// Remove a member
rs.remove("mongodb-secondary-3:27017")
```

## Backup and Restore

### Automated Backup (Recommended)

The project includes a comprehensive backup script that handles both single-node and replica set configurations:

```bash
# Create backup using the automated script
./scripts/backup.sh
```

Features:
- Automatic detection of MongoDB setup (single node vs replica set)
- Compression and timestamping of backups
- Automatic cleanup of old backups (configurable retention period)
- Error handling and validation

### Restore

```bash
# Restore from backup (with confirmation prompt)
./scripts/restore.sh ./backups/mongodb_backup_YYYYMMDD_HHMMSS.tar.gz

# List available backups
ls -la ./backups/
```

### Manual Backup (Advanced)

```bash
# Backup single database
docker exec mongodb_primary mongodump --db myapp --out /backup

# Backup all databases
docker exec mongodb_primary mongodump --out /backup
```

## Monitoring

### Automated Monitoring Script

Use the comprehensive monitoring script for real-time insights:

```bash
# Run monitoring dashboard
./scripts/monitor.sh
```

Features:
- Container health status
- Replica set status and member roles
- Database statistics and memory usage
- Connection counts and performance metrics
- MongoDB Express status

### Health Checks

```bash
# Check container health
docker ps

# Check MongoDB status
make status

# Monitor logs
make logs
```

### Performance Monitoring

```bash
# Monitor replica set with detailed dashboard
./scripts/monitor.sh

# Test replica set functionality
./scripts/test-replica-set.sh

# Check MongoDB metrics
docker exec mongodb_primary mongostat --host mongodb-primary:27017
```

## Script Testing and Validation

### Replica Set Testing

The project includes comprehensive testing scripts to validate replica set functionality:

```bash
# Run full replica set validation
./scripts/test-replica-set.sh
```

**Test Coverage:**
- Replica set status and member health
- Write operations to primary node
- Read operations from secondary nodes  
- Read preference configuration
- Connection string validation
- Oplog functionality
- Optional failover simulation

### Script Status

All management scripts have been thoroughly tested and validated:

| Script | Status | Description |
|--------|--------|-------------|
| `backup.sh` | **Tested** | Automated backup with error handling |
| `restore.sh` | **Tested** | Restore with confirmation prompts |
| `init-replica-set.sh` | **Tested** | Replica set initialization |
| `monitor.sh` | **Tested** | Real-time monitoring dashboard |
| `test-replica-set.sh` | **Tested** | Comprehensive validation suite |

**Recent Improvements (September 2025):**
- Fixed output parsing issues in test scripts
- Enhanced error handling and validation
- Improved backup directory management
- Added comprehensive replica set testing
- Better MongoDB Express integration

## Troubleshooting

### Common Issues

1. **Port Already in Use**
   ```bash
   # Check what's using the port
   netstat -tulpn | grep :27017
   
   # Modify ports in .env file
   ```

2. **Permission Issues**
   ```bash
   # Fix data directory permissions
   sudo chown -R 999:999 ./data
   ```

3. **Replica Set Initialization Failed**
   ```bash
   # Re-run initialization (script detects existing setup)
   ./scripts/init-replica-set.sh
   
   # Validate replica set functionality
   ./scripts/test-replica-set.sh
   
   # Check logs
   docker logs mongodb_primary
   ```

4. **Connection Issues**
   ```bash
   # Test connectivity
   mongosh mongodb://localhost:27017/admin
   
   # Check authentication
   mongosh mongodb://admin:admin123@localhost:27017/admin
   
   # Test replica set connection
   ./scripts/test-replica-set.sh
   ```

5. **Script Execution Issues**
   ```bash
   # Make scripts executable
   chmod +x scripts/*.sh
   
   # Run individual tests
   ./scripts/monitor.sh
   ./scripts/backup.sh
   ```

### Log Analysis

```bash
# View all logs
make logs

# View specific service logs
docker logs mongodb_primary
docker logs mongodb_secondary_1
docker logs mongo-express
```

## Security Considerations

### For Development
- Default passwords are used for convenience
- Authentication is enabled by default
- All services are exposed on localhost only

### For Production
- Change all default passwords
- Use strong passwords and proper secrets management
- Configure SSL/TLS encryption
- Implement proper network security
- Regular security updates

## File Structure

```
MongoDB/
├── README.md                      # This file
├── Makefile                       # Build and management commands
├── .env.example                   # Example environment variables
├── .env                          # Local environment variables (git-ignored)
├── docker-compose.yml            # Single node setup
├── docker-compose-cluster.yml    # Replica set cluster setup
├── mongod.conf                   # MongoDB configuration
├── mongod-replica.conf           # MongoDB replica set configuration
├── init-scripts/                 # Database initialization scripts
│   ├── 01-init-users.js         # Initial user setup
│   └── 02-sample-data.js        # Sample data
└── scripts/                      # Management scripts (all tested)
    ├── backup.sh                 # Automated backup with compression
    ├── restore.sh                # Restore with confirmation prompts  
    ├── monitor.sh                # Real-time monitoring dashboard
    ├── init-replica-set.sh       # Replica set initialization
    └── test-replica-set.sh       # Comprehensive testing suite
```

## Additional Resources

- [MongoDB Documentation](https://docs.mongodb.com/)
- [MongoDB Express](https://github.com/mongo-express/mongo-express)
- [Docker Official MongoDB Image](https://hub.docker.com/_/mongo)
- [MongoDB Replica Sets](https://docs.mongodb.com/manual/replication/)

## License

This project is for local development/testing purposes. Follow MongoDB's licensing terms for production use.
