// MongoDB Sample Data Script
// This script inserts sample data for testing

print('Inserting sample data...');

// Switch to application database
db = db.getSiblingDB('myapp');

// Sample users collection
db.users.insertMany([
  {
    _id: ObjectId(),
    name: 'John Doe',
    email: 'john.doe@example.com',
    role: 'admin',
    createdAt: new Date(),
    profile: {
      age: 30,
      city: 'New York',
      interests: ['programming', 'reading', 'gaming']
    }
  },
  {
    _id: ObjectId(),
    name: 'Jane Smith',
    email: 'jane.smith@example.com',
    role: 'user',
    createdAt: new Date(),
    profile: {
      age: 28,
      city: 'San Francisco',
      interests: ['design', 'photography', 'travel']
    }
  },
  {
    _id: ObjectId(),
    name: 'Bob Johnson',
    email: 'bob.johnson@example.com',
    role: 'user',
    createdAt: new Date(),
    profile: {
      age: 35,
      city: 'Chicago',
      interests: ['music', 'cooking', 'sports']
    }
  }
]);

print('Inserted sample users');

// Sample products collection
db.products.insertMany([
  {
    _id: ObjectId(),
    name: 'Laptop Pro',
    category: 'Electronics',
    price: 1299.99,
    description: 'High-performance laptop for professionals',
    inStock: true,
    quantity: 50,
    tags: ['laptop', 'computer', 'professional'],
    specifications: {
      cpu: 'Intel i7',
      ram: '16GB',
      storage: '512GB SSD',
      screen: '15.6 inch'
    },
    createdAt: new Date()
  },
  {
    _id: ObjectId(),
    name: 'Wireless Headphones',
    category: 'Electronics',
    price: 199.99,
    description: 'Premium wireless headphones with noise cancellation',
    inStock: true,
    quantity: 100,
    tags: ['headphones', 'audio', 'wireless'],
    specifications: {
      type: 'Over-ear',
      batteryLife: '30 hours',
      noiseCancellation: true,
      bluetooth: '5.0'
    },
    createdAt: new Date()
  },
  {
    _id: ObjectId(),
    name: 'Coffee Mug',
    category: 'Home & Kitchen',
    price: 19.99,
    description: 'Ceramic coffee mug with ergonomic handle',
    inStock: true,
    quantity: 200,
    tags: ['mug', 'coffee', 'ceramic'],
    specifications: {
      material: 'Ceramic',
      capacity: '350ml',
      dishwasherSafe: true,
      microwaveSafe: true
    },
    createdAt: new Date()
  }
]);

print('Inserted sample products');

// Sample orders collection
db.orders.insertMany([
  {
    _id: ObjectId(),
    userId: ObjectId(),
    orderNumber: 'ORD-001',
    status: 'completed',
    totalAmount: 1299.99,
    items: [
      {
        productId: ObjectId(),
        name: 'Laptop Pro',
        quantity: 1,
        price: 1299.99
      }
    ],
    shippingAddress: {
      street: '123 Main St',
      city: 'New York',
      state: 'NY',
      zipCode: '10001',
      country: 'USA'
    },
    createdAt: new Date(),
    updatedAt: new Date()
  },
  {
    _id: ObjectId(),
    userId: ObjectId(),
    orderNumber: 'ORD-002',
    status: 'pending',
    totalAmount: 219.98,
    items: [
      {
        productId: ObjectId(),
        name: 'Wireless Headphones',
        quantity: 1,
        price: 199.99
      },
      {
        productId: ObjectId(),
        name: 'Coffee Mug',
        quantity: 1,
        price: 19.99
      }
    ],
    shippingAddress: {
      street: '456 Oak Ave',
      city: 'San Francisco',
      state: 'CA',
      zipCode: '94102',
      country: 'USA'
    },
    createdAt: new Date(),
    updatedAt: new Date()
  }
]);

print('Inserted sample orders');

// Create indexes for better performance
db.users.createIndex({ email: 1 }, { unique: true });
db.users.createIndex({ role: 1 });
db.products.createIndex({ category: 1 });
db.products.createIndex({ name: 'text', description: 'text' });
db.orders.createIndex({ userId: 1 });
db.orders.createIndex({ status: 1 });
db.orders.createIndex({ createdAt: -1 });

print('Created indexes for collections');

// Switch to test database and add test data
db = db.getSiblingDB('testdb');

db.test_collection.insertMany([
  {
    _id: ObjectId(),
    testField: 'Test Value 1',
    number: 42,
    active: true,
    createdAt: new Date()
  },
  {
    _id: ObjectId(),
    testField: 'Test Value 2',
    number: 84,
    active: false,
    createdAt: new Date()
  }
]);

print('Inserted test data');

print('Sample data insertion completed successfully!');
