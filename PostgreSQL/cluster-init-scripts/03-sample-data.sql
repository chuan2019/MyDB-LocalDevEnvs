-- Sample database schema and data for cluster development/testing

\echo 'Creating sample tables and data for cluster...'

-- Create a sample users table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    full_name VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create a sample posts table
CREATE TABLE IF NOT EXISTS posts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    content TEXT,
    published BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create a sample tags table
CREATE TABLE IF NOT EXISTS tags (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT
);

-- Create a many-to-many relationship table for posts and tags
CREATE TABLE IF NOT EXISTS post_tags (
    post_id INTEGER REFERENCES posts(id) ON DELETE CASCADE,
    tag_id INTEGER REFERENCES tags(id) ON DELETE CASCADE,
    PRIMARY KEY (post_id, tag_id)
);

-- Create a sample analytics table for read-heavy workloads
CREATE TABLE IF NOT EXISTS page_views (
    id SERIAL PRIMARY KEY,
    post_id INTEGER REFERENCES posts(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    ip_address INET,
    user_agent TEXT,
    viewed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data
INSERT INTO users (username, email, full_name) VALUES
    ('john_doe', 'john@example.com', 'John Doe'),
    ('jane_smith', 'jane@example.com', 'Jane Smith'),
    ('bob_wilson', 'bob@example.com', 'Bob Wilson'),
    ('alice_brown', 'alice@example.com', 'Alice Brown'),
    ('charlie_davis', 'charlie@example.com', 'Charlie Davis'),
    ('diana_johnson', 'diana@example.com', 'Diana Johnson'),
    ('frank_miller', 'frank@example.com', 'Frank Miller'),
    ('grace_taylor', 'grace@example.com', 'Grace Taylor')
ON CONFLICT (username) DO NOTHING;

INSERT INTO tags (name, description) VALUES
    ('technology', 'Posts about technology and programming'),
    ('tutorial', 'How-to guides and tutorials'),
    ('news', 'Latest news and updates'),
    ('review', 'Product and service reviews'),
    ('opinion', 'Personal opinions and thoughts'),
    ('database', 'Database related content'),
    ('performance', 'Performance optimization topics')
ON CONFLICT (name) DO NOTHING;

INSERT INTO posts (user_id, title, content, published) VALUES
    (1, 'Getting Started with PostgreSQL', 'This is a comprehensive guide to getting started with PostgreSQL...', true),
    (1, 'Docker Best Practices', 'Learn the best practices for using Docker in production...', true),
    (2, 'JavaScript Tips and Tricks', 'Here are some useful JavaScript tips that will improve your code...', true),
    (2, 'Database Design Patterns', 'Understanding common database design patterns...', false),
    (3, 'Introduction to Machine Learning', 'A beginner-friendly introduction to ML concepts...', true),
    (4, 'Web Security Fundamentals', 'Essential security practices for web developers...', true),
    (5, 'Performance Optimization Guide', 'How to optimize your application performance...', false),
    (6, 'PostgreSQL Replication Setup', 'Setting up master-slave replication in PostgreSQL...', true),
    (7, 'Load Balancing Strategies', 'Different approaches to load balancing database connections...', true),
    (8, 'Monitoring Database Performance', 'Tools and techniques for monitoring PostgreSQL performance...', true);

-- Associate posts with tags
INSERT INTO post_tags (post_id, tag_id) VALUES
    (1, 1), (1, 2), (1, 6),  -- PostgreSQL post: technology, tutorial, database
    (2, 1), (2, 2),          -- Docker post: technology, tutorial
    (3, 1), (3, 2),          -- JavaScript post: technology, tutorial
    (4, 1), (4, 6),          -- Database post: technology, database
    (5, 1), (5, 2),          -- ML post: technology, tutorial
    (6, 1),                  -- Security post: technology
    (7, 1), (7, 2), (7, 7),  -- Performance post: technology, tutorial, performance
    (8, 1), (8, 6), (8, 2),  -- Replication post: technology, database, tutorial
    (9, 1), (9, 7), (9, 6),  -- Load balancing: technology, performance, database
    (10, 1), (10, 7), (10, 6); -- Monitoring: technology, performance, database

-- Generate sample page views for analytics
INSERT INTO page_views (post_id, user_id, ip_address, user_agent)
SELECT 
    (RANDOM() * 10 + 1)::INTEGER as post_id,
    CASE WHEN RANDOM() > 0.3 THEN (RANDOM() * 8 + 1)::INTEGER ELSE NULL END as user_id,
    ('192.168.1.' || (RANDOM() * 254 + 1)::INTEGER)::INET as ip_address,
    'Mozilla/5.0 (compatible; TestBot/1.0)' as user_agent
FROM generate_series(1, 1000);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_posts_user_id ON posts(user_id);
CREATE INDEX IF NOT EXISTS idx_posts_published ON posts(published);
CREATE INDEX IF NOT EXISTS idx_posts_created_at ON posts(created_at);
CREATE INDEX IF NOT EXISTS idx_page_views_post_id ON page_views(post_id);
CREATE INDEX IF NOT EXISTS idx_page_views_viewed_at ON page_views(viewed_at);

-- Create views for analytics (read-heavy workloads)
CREATE OR REPLACE VIEW published_posts AS
SELECT 
    p.id,
    p.title,
    p.content,
    p.created_at,
    u.username,
    u.full_name,
    u.email
FROM posts p
JOIN users u ON p.user_id = u.id
WHERE p.published = true
ORDER BY p.created_at DESC;

CREATE OR REPLACE VIEW post_analytics AS
SELECT 
    p.id,
    p.title,
    u.username as author,
    COUNT(pv.id) as view_count,
    COUNT(DISTINCT pv.user_id) as unique_viewers,
    p.created_at
FROM posts p
JOIN users u ON p.user_id = u.id
LEFT JOIN page_views pv ON p.id = pv.post_id
WHERE p.published = true
GROUP BY p.id, p.title, u.username, p.created_at
ORDER BY view_count DESC;

-- Create a function to simulate read-heavy workload
CREATE OR REPLACE FUNCTION get_popular_posts(limit_count INTEGER DEFAULT 10)
RETURNS TABLE(
    post_id INTEGER,
    title VARCHAR(200),
    author VARCHAR(50),
    view_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pa.id,
        pa.title,
        pa.author,
        pa.view_count
    FROM post_analytics pa
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

\echo 'Sample data creation for cluster completed!'
