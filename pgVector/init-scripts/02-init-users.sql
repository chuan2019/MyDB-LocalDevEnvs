-- This script will be executed as the postgres superuser
-- The user and database are already created by Docker environment variables
-- We just need to ensure the user has proper permissions

-- Connect to the created database
\c pgvector_db;

-- Grant all privileges to the user on the database
GRANT ALL PRIVILEGES ON DATABASE pgvector_db TO pgvector_user;
GRANT ALL ON SCHEMA public TO pgvector_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO pgvector_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO pgvector_user;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO pgvector_user;

-- Allow the user to create tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO pgvector_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO pgvector_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO pgvector_user;