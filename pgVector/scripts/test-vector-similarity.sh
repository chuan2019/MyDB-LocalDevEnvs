#!/bin/bash

# Test Vector Similarity Search Functions
# This script tests various vector similarity search operations using pgvector

set -e

# Load environment variables
if [ -f "../.env" ]; then
    export $(cat ../.env | grep -v '^#' | xargs)
fi

# Set database credentials from environment variables
POSTGRES_USER=${POSTGRES_USER:-pgvector_user}
POSTGRES_DB=${POSTGRES_DB:-pgvector_db}
CONTAINER_NAME=${CONTAINER_NAME:-pgvector_db}

echo "========================================="
echo "pgVector Similarity Search Test Suite"
echo "========================================="
echo "Database: $POSTGRES_DB"
echo "User: $POSTGRES_USER"
echo "Container: $CONTAINER_NAME"
echo "========================================="

# Change to parent directory for docker-compose
cd "$(dirname "$0")/.." || exit 1

# Function to execute SQL and display results
execute_sql() {
    local query="$1"
    local description="$2"
    
    echo ""
    echo "Test: $description"
    echo "Query: $query"
    echo "Results:"
    docker compose exec -T postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "$query"
    echo "-------------------------------------------"
}

# Test 1: Basic Vector Operations
echo ""
echo "TEST 1: Basic Vector Operations"
execute_sql "
DROP TABLE IF EXISTS test_vectors;
CREATE TABLE test_vectors (
    id SERIAL PRIMARY KEY,
    name TEXT,
    embedding vector(3)
);

INSERT INTO test_vectors (name, embedding) VALUES 
    ('Point A', '[1, 2, 3]'),
    ('Point B', '[4, 5, 6]'),
    ('Point C', '[1, 2, 4]'),
    ('Point D', '[7, 8, 9]');

SELECT name, embedding FROM test_vectors ORDER BY id;
" "Create test vectors and display them"

# Test 2: L2 Distance (Euclidean Distance)
echo ""
echo "TEST 2: L2 Distance (Euclidean Distance)"
execute_sql "
SELECT 
    name,
    embedding,
    embedding <-> '[1, 2, 3]' AS l2_distance
FROM test_vectors 
ORDER BY embedding <-> '[1, 2, 3]'
LIMIT 3;
" "Find vectors closest to [1,2,3] using L2 distance"

# Test 3: Cosine Distance
echo ""
echo "TEST 3: Cosine Distance"
execute_sql "
SELECT 
    name,
    embedding,
    embedding <=> '[1, 2, 3]' AS cosine_distance
FROM test_vectors 
ORDER BY embedding <=> '[1, 2, 3]'
LIMIT 3;
" "Find vectors most similar to [1,2,3] using cosine distance"

# Test 4: Inner Product (Dot Product)
echo ""
echo "TEST 4: Inner Product (Dot Product)"
execute_sql "
SELECT 
    name,
    embedding,
    embedding <#> '[1, 2, 3]' AS negative_inner_product
FROM test_vectors 
ORDER BY embedding <#> '[1, 2, 3]'
LIMIT 3;
" "Find vectors with highest inner product with [1,2,3]"

# Test 5: Test with Product Embeddings (from sample data)
echo ""
echo "TEST 5: Product Similarity Search"
execute_sql "
-- Create a query vector with same dimensions as products (384D)
-- We'll just use the first product's embedding as a reference
WITH query_vector AS (
    SELECT embedding FROM products LIMIT 1
)
SELECT 
    name,
    description,
    price,
    embedding <-> (SELECT embedding FROM query_vector) AS similarity_score
FROM products 
ORDER BY embedding <-> (SELECT embedding FROM query_vector)
LIMIT 3;
" "Find products similar to the first product's embedding"

# Test 6: Range Search
echo ""
echo "TEST 6: Range Search (Distance Threshold)"
execute_sql "
SELECT 
    name,
    embedding,
    embedding <-> '[1, 2, 3]' AS distance
FROM test_vectors 
WHERE embedding <-> '[1, 2, 3]' < 5.0
ORDER BY embedding <-> '[1, 2, 3]';
" "Find all vectors within distance 5.0 of [1,2,3]"

# Test 7: Vector Arithmetic
echo ""
echo "TEST 7: Vector Arithmetic"
execute_sql "
SELECT 
    '[1, 2, 3]'::vector + '[1, 1, 1]'::vector AS vector_addition,
    '[4, 5, 6]'::vector - '[1, 2, 3]'::vector AS vector_subtraction;
" "Test vector arithmetic operations"

# Test 8: Index Performance Test
echo ""
echo "TEST 8: Index Usage Verification"
execute_sql "
EXPLAIN (ANALYZE, BUFFERS) 
SELECT name, embedding <-> '[0.1, 0.2, 0.3]' AS distance 
FROM products 
ORDER BY embedding <-> '[0.1, 0.2, 0.3]' 
LIMIT 5;
" "Verify that vector index is being used"

# Test 9: High-Dimensional Vector Test
echo ""
echo "TEST 9: High-Dimensional Vectors"
execute_sql "
DROP TABLE IF EXISTS high_dim_vectors;
CREATE TABLE high_dim_vectors (
    id SERIAL PRIMARY KEY,
    name TEXT,
    embedding vector(10)
);

INSERT INTO high_dim_vectors (name, embedding) VALUES 
    ('HD Vector 1', '[0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]'),
    ('HD Vector 2', '[1.0, 0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.2, 0.1]'),
    ('HD Vector 3', '[0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5]');

SELECT 
    name,
    embedding <-> '[0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]' AS distance
FROM high_dim_vectors 
ORDER BY embedding <-> '[0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]';
" "Test with higher-dimensional vectors (10D)"

# Test 10: Vector Normalization
echo ""
echo "TEST 10: Vector Normalization"
execute_sql "
WITH normalized_test AS (
    SELECT 
        name,
        embedding,
        embedding / sqrt(embedding <#> embedding) AS normalized_embedding
    FROM test_vectors
)
SELECT 
    name,
    embedding AS original,
    normalized_embedding,
    sqrt(normalized_embedding <#> normalized_embedding) AS norm_check
FROM normalized_test;
" "Test vector normalization (should result in unit vectors)"

echo ""
echo "All vector similarity tests completed!"
echo ""
echo "Summary of Distance Metrics:"
echo "   • <-> : L2 distance (Euclidean)"
echo "   • <=> : Cosine distance" 
echo "   • <#> : Negative inner product"
echo ""
echo "Key Findings:"
echo "   • Smaller L2 distance = more similar vectors"
echo "   • Smaller cosine distance = more similar direction"
echo "   • Larger inner product = more aligned vectors"
echo ""