-- Sample database schema and data for development/testing

\echo 'Creating sample tables and data...'

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

-- Insert sample data
INSERT INTO users (username, email, full_name) VALUES
    ('john_doe', 'john@example.com', 'John Doe'),
    ('jane_smith', 'jane@example.com', 'Jane Smith'),
    ('bob_wilson', 'bob@example.com', 'Bob Wilson'),
    ('alice_brown', 'alice@example.com', 'Alice Brown'),
    ('charlie_davis', 'charlie@example.com', 'Charlie Davis')
ON CONFLICT (username) DO NOTHING;

INSERT INTO tags (name, description) VALUES
    ('technology', 'Posts about technology and programming'),
    ('tutorial', 'How-to guides and tutorials'),
    ('news', 'Latest news and updates'),
    ('review', 'Product and service reviews'),
    ('opinion', 'Personal opinions and thoughts')
ON CONFLICT (name) DO NOTHING;

INSERT INTO posts (user_id, title, content, published) VALUES
    (1, 'Getting Started with PostgreSQL', 'This is a comprehensive guide to getting started with PostgreSQL...', true),
    (1, 'Docker Best Practices', 'Learn the best practices for using Docker in production...', true),
    (2, 'JavaScript Tips and Tricks', 'Here are some useful JavaScript tips that will improve your code...', true),
    (2, 'Database Design Patterns', 'Understanding common database design patterns...', false),
    (3, 'Introduction to Machine Learning', 'A beginner-friendly introduction to ML concepts...', true),
    (4, 'Web Security Fundamentals', 'Essential security practices for web developers...', true),
    (5, 'Performance Optimization Guide', 'How to optimize your application performance...', false);

-- Associate posts with tags
INSERT INTO post_tags (post_id, tag_id) VALUES
    (1, 1), (1, 2),  -- PostgreSQL post: technology, tutorial
    (2, 1), (2, 2),  -- Docker post: technology, tutorial
    (3, 1), (3, 2),  -- JavaScript post: technology, tutorial
    (4, 1),          -- Database post: technology
    (5, 1), (5, 2),  -- ML post: technology, tutorial
    (6, 1),          -- Security post: technology
    (7, 1), (7, 2);  -- Performance post: technology, tutorial

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_posts_user_id ON posts(user_id);
CREATE INDEX IF NOT EXISTS idx_posts_published ON posts(published);
CREATE INDEX IF NOT EXISTS idx_posts_created_at ON posts(created_at);

-- Create a view for published posts with user information
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

\echo 'Sample data creation completed!'
