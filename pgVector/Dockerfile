# Use official PostgreSQL image as base
FROM postgres:latest

# Install build dependencies and pgvector
RUN apt-get update && \
    apt-get install -y \
        build-essential \
        git \
        postgresql-server-dev-all && \
    # Clone and build pgvector
    git clone --branch v0.5.1 https://github.com/pgvector/pgvector.git /tmp/pgvector && \
    cd /tmp/pgvector && \
    make && \
    make install && \
    # Clean up
    cd / && \
    rm -rf /tmp/pgvector && \
    apt-get remove -y build-essential git postgresql-server-dev-all && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy configuration files
COPY postgresql.conf /etc/postgresql/postgresql.conf
COPY postgresql-primary.conf /etc/postgresql/postgresql-primary.conf
COPY postgresql-replica.conf /etc/postgresql/postgresql-replica.conf

# Copy initialization scripts
COPY init-scripts /docker-entrypoint-initdb.d

# Set default command
CMD ["postgres", "-c", "config_file=/etc/postgresql/postgresql.conf"]