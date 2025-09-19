# pgvector Local Development Environment

This project sets up a local development environment for the pgvector vector database using Docker Compose. It provides a complete setup for PostgreSQL with the pgvector extension, allowing you to work with vector embeddings efficiently.

## Project Structure

- **.env**: Contains environment variables for PostgreSQL configuration (database name, user, password).
- **.env.example**: Template for the .env file with example values.
- **docker-compose.yml**: Defines services, networks, and volumes for the PostgreSQL setup.
- **docker-compose-cluster.yml**: Defines a clustered setup for PostgreSQL with replication.
- **Makefile**: Contains commands for managing Docker containers.
- **postgresql.conf**: Main configuration settings for PostgreSQL.
- **postgresql-primary.conf**: Configuration for the primary PostgreSQL instance.
- **postgresql-replica.conf**: Configuration for the replica PostgreSQL instance.
- **setup-replica.sh**: Script to set up replication configuration.
- **init-scripts/**: Contains SQL scripts for initializing the database.
  - **01-init-pgvector.sql**: Initializes the pgvector extension.
  - **02-init-users.sql**: Creates necessary database users and roles.
  - **03-sample-data.sql**: Populates the database with sample data.
- **cluster-init-scripts/**: Scripts for initializing the cluster setup.
  - **01-setup-replication.sh**: Sets up replication between instances.
  - **02-init-pgvector.sh**: Initializes pgvector on the replica.
  - **03-init-users.sh**: Creates users on the replica.
- **scripts/**: Utility scripts for managing the database.
  - **backup.sh**: Performs database backup.
  - **restore.sh**: Restores the database from a backup.
  - **monitor.sh**: Monitors the health of PostgreSQL instances.
  - **test-replication.sh**: Tests the replication setup.

## Getting Started

1. **Clone the repository**:
   ```
   git clone <repository-url>
   cd pgvector-local-dev
   ```

2. **Set up environment variables**:
   Copy `.env.example` to `.env` and update the values as needed.

3. **Start the services**:
   Use Docker Compose to start the PostgreSQL services:
   ```
   docker-compose up -d
   ```

4. **Initialize the database**:
   Run the initialization scripts to set up the database:
   ```
   docker-compose exec db psql -U <user> -d <database> -f /init-scripts/01-init-pgvector.sql
   docker-compose exec db psql -U <user> -d <database> -f /init-scripts/02-init-users.sql
   docker-compose exec db psql -U <user> -d <database> -f /init-scripts/03-sample-data.sql
   ```

5. **Access the database**:
   You can connect to the PostgreSQL database using your preferred client with the credentials specified in the `.env` file.

## Usage

- Use the provided scripts in the `scripts/` directory for backup, restore, monitoring, and testing replication.
- Modify the configuration files as needed to suit your development requirements.

## Vector Similarity Search Testing

This setup includes comprehensive test cases for vector similarity search operations:

### Running Vector Tests

```bash
# Run the complete vector similarity test suite
./scripts/test-vector-similarity.sh

# Or run specific SQL test cases
docker compose exec postgres psql -U pgvector_user -d pgvector_db -f /init-scripts/04-vector-test-cases.sql
```

### Test Categories

1. **Basic Vector Operations** - Creating and querying vector data
2. **Distance Metrics** - L2 distance, cosine similarity, inner product
3. **Product Recommendations** - Similarity-based product matching
4. **Document Similarity** - Text content similarity search
5. **User Preference Matching** - Finding similar user profiles
6. **Performance Testing** - Index usage and query optimization
7. **Vector Arithmetic** - Addition, subtraction, scalar multiplication
8. **High-Dimensional Vectors** - Testing with vectors up to 384 dimensions
9. **Anomaly Detection** - Finding outliers in vector data
10. **Clustering Analysis** - Grouping similar vectors

### Available Distance Operators

- `<->` : L2 distance (Euclidean) - smaller values = more similar
- `<=>` : Cosine distance - smaller values = more similar direction  
- `<#>` : Negative inner product - larger absolute values = more aligned

### Sample Use Cases

The test suite demonstrates practical applications including:
- E-commerce product recommendations
- Document similarity search
- User behavior analysis
- Content-based filtering
- Anomaly detection in high-dimensional data

## License

This project is licensed under the MIT License. See the LICENSE file for details.