-- Sample data for pgVector database
-- This script creates sample tables and inserts data to demonstrate pgvector functionality

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create products table with vector embeddings
CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2),
    embedding vector(384), -- 384-dimensional vector for embeddings
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create orders table
CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    product_id INTEGER REFERENCES products(id),
    quantity INTEGER NOT NULL DEFAULT 1,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample users
INSERT INTO users (id, name, email) VALUES
(1, 'Alice Johnson', 'alice@example.com'),
(2, 'Bob Smith', 'bob@example.com'),
(3, 'Charlie Brown', 'charlie@example.com')
ON CONFLICT (email) DO NOTHING;

-- Insert sample products (with random vectors for demonstration)
INSERT INTO products (id, name, description, price, embedding) VALUES
(1, 'Laptop Computer', 'High-performance laptop for development work', 999.99, 
    ARRAY(SELECT random() FROM generate_series(1, 384))::vector),
(2, 'Wireless Mouse', 'Ergonomic wireless mouse with precision tracking', 29.99,
    ARRAY(SELECT random() FROM generate_series(1, 384))::vector),
(3, 'Mechanical Keyboard', 'RGB mechanical keyboard with tactile switches', 149.99,
    ARRAY(SELECT random() FROM generate_series(1, 384))::vector)
ON CONFLICT (id) DO NOTHING;

-- Insert sample orders
INSERT INTO orders (id, user_id, product_id, quantity, order_date) VALUES
(1, 1, 1, 1, NOW()),
(2, 2, 2, 2, NOW()),
(3, 3, 3, 1, NOW()),
(4, 1, 2, 1, NOW() - INTERVAL '1 day'),
(5, 2, 1, 1, NOW() - INTERVAL '2 days')
ON CONFLICT (id) DO NOTHING;

-- Create an index on the vector column for efficient similarity search
CREATE INDEX CONCURRENTLY IF NOT EXISTS products_embedding_idx 
ON products USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

-- Demonstrate vector similarity search
-- This is a sample query that users can run:
-- SELECT name, description, embedding <=> '[1,2,3,...]' AS similarity 
-- FROM products 
-- ORDER BY embedding <=> '[1,2,3,...]' 
-- LIMIT 5;