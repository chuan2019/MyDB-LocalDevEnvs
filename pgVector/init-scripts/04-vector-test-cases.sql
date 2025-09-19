-- pgVector Similarity Search Test Cases
-- Run these tests to verify vector search functionality

-- Test Case 1: Document Similarity Search
-- Create a test table for document embeddings
DROP TABLE IF EXISTS documents;
CREATE TABLE documents (
    id SERIAL PRIMARY KEY,
    title TEXT,
    content TEXT,
    embedding vector(5)  -- Using 5D for simplicity
);

-- Insert sample documents with embeddings representing their content
INSERT INTO documents (title, content, embedding) VALUES 
    ('AI Technology', 'Article about artificial intelligence and machine learning', '[0.8, 0.2, 0.9, 0.1, 0.7]'),
    ('Database Systems', 'Guide to relational and NoSQL databases', '[0.1, 0.9, 0.2, 0.8, 0.3]'),
    ('Machine Learning', 'Introduction to ML algorithms and techniques', '[0.9, 0.1, 0.8, 0.2, 0.6]'),
    ('Web Development', 'Building modern web applications', '[0.3, 0.7, 0.1, 0.9, 0.4]'),
    ('Data Science', 'Analytics and statistical modeling', '[0.7, 0.3, 0.6, 0.4, 0.8]');

-- Test Case 1a: Find documents similar to "AI/ML content"
-- Query embedding: [0.85, 0.15, 0.9, 0.1, 0.7]
SELECT 
    title,
    content,
    embedding <-> '[0.85, 0.15, 0.9, 0.1, 0.7]' AS l2_distance,
    embedding <=> '[0.85, 0.15, 0.9, 0.1, 0.7]' AS cosine_distance
FROM documents 
ORDER BY embedding <-> '[0.85, 0.15, 0.9, 0.1, 0.7]'
LIMIT 3;

-- Test Case 2: Product Recommendation System
-- Create a more realistic product recommendation test
DROP TABLE IF EXISTS product_features;
CREATE TABLE product_features (
    id SERIAL PRIMARY KEY,
    product_name TEXT,
    category TEXT,
    features vector(4)  -- [price_tier, quality, popularity, innovation]
);

-- Insert products with feature vectors
INSERT INTO product_features (product_name, category, features) VALUES 
    ('iPhone 15', 'Electronics', '[0.9, 0.95, 0.9, 0.8]'),     -- High price, high quality, popular, innovative
    ('Samsung Galaxy', 'Electronics', '[0.8, 0.9, 0.85, 0.75]'),
    ('Budget Phone', 'Electronics', '[0.2, 0.6, 0.7, 0.3]'),   -- Low price, medium quality, popular, less innovative
    ('Premium Laptop', 'Computers', '[0.95, 0.9, 0.8, 0.85]'),
    ('Basic Laptop', 'Computers', '[0.3, 0.65, 0.75, 0.4]'),
    ('Gaming Console', 'Gaming', '[0.7, 0.85, 0.95, 0.7]'),
    ('Tablet Pro', 'Electronics', '[0.8, 0.88, 0.82, 0.78]');

-- Test Case 2a: Find products similar to "Premium, high-quality, popular items"
-- Query: [0.9, 0.9, 0.85, 0.8]
SELECT 
    product_name,
    category,
    features,
    features <-> '[0.9, 0.9, 0.85, 0.8]' AS similarity_score
FROM product_features 
ORDER BY features <-> '[0.9, 0.9, 0.85, 0.8]'
LIMIT 5;

-- Test Case 2b: Find budget-friendly alternatives
-- Query: [0.3, 0.6, 0.7, 0.4]
SELECT 
    product_name,
    category,
    features,
    features <-> '[0.3, 0.6, 0.7, 0.4]' AS similarity_score
FROM product_features 
ORDER BY features <-> '[0.3, 0.6, 0.7, 0.4]'
LIMIT 3;

-- Test Case 3: User Preference Matching
DROP TABLE IF EXISTS user_preferences;
CREATE TABLE user_preferences (
    user_id SERIAL PRIMARY KEY,
    username TEXT,
    preference_vector vector(6)  -- [sports, tech, music, movies, books, travel]
);

INSERT INTO user_preferences (username, preference_vector) VALUES 
    ('Alice', '[0.8, 0.9, 0.3, 0.7, 0.6, 0.4]'),    -- Tech-savvy, likes sports and movies
    ('Bob', '[0.2, 0.4, 0.9, 0.8, 0.7, 0.3]'),      -- Music and movie lover, bookworm
    ('Charlie', '[0.9, 0.5, 0.4, 0.6, 0.3, 0.8]'),  -- Sports enthusiast, loves travel
    ('Diana', '[0.1, 0.8, 0.6, 0.4, 0.9, 0.5]'),    -- Tech lover, bookworm
    ('Eve', '[0.6, 0.3, 0.8, 0.9, 0.4, 0.7]');      -- Music and movie enthusiast, likes travel

-- Test Case 3a: Find users similar to a tech-loving sports fan
-- Query: [0.85, 0.9, 0.2, 0.6, 0.4, 0.3]
SELECT 
    username,
    preference_vector,
    preference_vector <=> '[0.85, 0.9, 0.2, 0.6, 0.4, 0.3]' AS cosine_similarity
FROM user_preferences 
ORDER BY preference_vector <=> '[0.85, 0.9, 0.2, 0.6, 0.4, 0.3]'
LIMIT 3;

-- Test Case 4: Anomaly Detection
-- Find outliers in the data
WITH avg_embedding AS (
    SELECT 
        AVG(preference_vector[1]) as avg_sports,
        AVG(preference_vector[2]) as avg_tech,
        AVG(preference_vector[3]) as avg_music,
        AVG(preference_vector[4]) as avg_movies,
        AVG(preference_vector[5]) as avg_books,
        AVG(preference_vector[6]) as avg_travel
    FROM user_preferences
)
SELECT 
    username,
    preference_vector,
    preference_vector <-> ARRAY[avg_sports, avg_tech, avg_music, avg_movies, avg_books, avg_travel]::vector AS distance_from_avg
FROM user_preferences, avg_embedding
ORDER BY distance_from_avg DESC;

-- Test Case 5: Clustering Analysis
-- Group similar users using distance thresholds
WITH user_distances AS (
    SELECT 
        u1.username AS user1,
        u2.username AS user2,
        u1.preference_vector <-> u2.preference_vector AS distance
    FROM user_preferences u1
    CROSS JOIN user_preferences u2
    WHERE u1.user_id < u2.user_id
)
SELECT 
    user1,
    user2,
    distance,
    CASE 
        WHEN distance < 0.5 THEN 'Very Similar'
        WHEN distance < 1.0 THEN 'Similar'
        WHEN distance < 1.5 THEN 'Somewhat Similar'
        ELSE 'Different'
    END AS similarity_category
FROM user_distances
ORDER BY distance;

-- Test Case 6: Performance Test with Larger Dataset
-- Create a larger dataset for performance testing
DROP TABLE IF EXISTS large_vectors;
CREATE TABLE large_vectors (
    id SERIAL PRIMARY KEY,
    vector_data vector(100)
);

-- Insert random-like vectors (simplified for testing)
INSERT INTO large_vectors (vector_data) 
SELECT 
    ARRAY(
        SELECT (random() * 2 - 1)::float 
        FROM generate_series(1, 100)
    )::vector
FROM generate_series(1, 1000);

-- Create index for performance
CREATE INDEX IF NOT EXISTS large_vectors_idx ON large_vectors USING ivfflat (vector_data vector_l2_ops);

-- Test query performance
EXPLAIN (ANALYZE, BUFFERS) 
SELECT id, vector_data <-> ARRAY(SELECT (random() * 2 - 1)::float FROM generate_series(1, 100))::vector AS distance
FROM large_vectors 
ORDER BY vector_data <-> ARRAY(SELECT (random() * 2 - 1)::float FROM generate_series(1, 100))::vector
LIMIT 10;

-- Test Case 7: Vector Operations and Functions
SELECT 
    'Vector Addition' AS operation,
    '[1, 2, 3]'::vector + '[4, 5, 6]'::vector AS result
UNION ALL
SELECT 
    'Vector Subtraction',
    '[4, 5, 6]'::vector - '[1, 2, 3]'::vector
UNION ALL
SELECT 
    'Scalar Multiplication',
    '[1, 2, 3]'::vector * 0.5
UNION ALL
SELECT 
    'Vector Dimensions',
    vector_dims('[1, 2, 3, 4, 5]'::vector)::text::vector;

-- Test Case 8: Distance Metric Comparison
WITH test_vectors AS (
    SELECT 
        'Vector A' AS name, '[1, 0, 0]'::vector AS vec
    UNION ALL SELECT 
        'Vector B', '[0, 1, 0]'::vector
    UNION ALL SELECT 
        'Vector C', '[1, 1, 0]'::vector
    UNION ALL SELECT 
        'Vector D', '[0.5, 0.5, 0]'::vector
)
SELECT 
    name,
    vec,
    vec <-> '[1, 0, 0]'::vector AS l2_distance,
    vec <=> '[1, 0, 0]'::vector AS cosine_distance,
    vec <#> '[1, 0, 0]'::vector AS neg_inner_product
FROM test_vectors
ORDER BY l2_distance;

-- Cleanup (optional)
-- DROP TABLE IF EXISTS documents;
-- DROP TABLE IF EXISTS product_features;
-- DROP TABLE IF EXISTS user_preferences;
-- DROP TABLE IF EXISTS large_vectors;