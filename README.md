# MyDB-LocalDevEnvs

Local development environments for databases using Docker Compose.

## Included Databases

### Relational Databases

- **[PostgreSQL](./PostgreSQL/)** - Relational database with clustering support

### NoSQL Databases

- **[MongoDB](./MongoDB/)** - Document database with replica set support
- **[ScyllaDB](./ScyllaDB/)** - NoSQL database with ScyllaDB

### Vector Databases

- **[pgVector](./pgVector/)** - PostgreSQL with pgvector extension for vector similarity search
- **[Weaviate](./Weaviate/)** - Vector database for AI/ML applications

### Graph Databases

- **[Neo4J](./Neo4J/)** - Graph database with single-node support (cluster mode needs Enterprise version)
- **[MemGraph](./MemGraph/)** - In memory Graph database with single-node and cluster support

Each directory contains Docker Compose configurations and setup scripts for quick local deployment.