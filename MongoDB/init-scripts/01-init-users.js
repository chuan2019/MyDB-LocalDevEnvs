// MongoDB User Initialization Script
// This script creates application users and databases

print('Creating application database and users...');

// Switch to admin database to create users
db = db.getSiblingDB('admin');

// Create application database
db = db.getSiblingDB('myapp');

// Create application user with read/write permissions
db.createUser({
  user: 'appuser',
  pwd: 'apppass123',
  roles: [
    {
      role: 'readWrite',
      db: 'myapp'
    }
  ]
});

print('Application user "appuser" created for database "myapp"');

// Create read-only user for monitoring/analytics
db.createUser({
  user: 'readonly',
  pwd: 'readonly123',
  roles: [
    {
      role: 'read',
      db: 'myapp'
    }
  ]
});

print('Read-only user "readonly" created for database "myapp"');

// Switch to test database and create test user
db = db.getSiblingDB('testdb');

db.createUser({
  user: 'testuser',
  pwd: 'testpass123',
  roles: [
    {
      role: 'readWrite',
      db: 'testdb'
    }
  ]
});

print('Test user "testuser" created for database "testdb"');

print('User initialization completed successfully!');
