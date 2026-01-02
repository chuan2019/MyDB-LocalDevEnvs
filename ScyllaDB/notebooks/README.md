# ScyllaDB Jupyter Notebooks

Interactive notebooks for learning and testing ScyllaDB.

## Prerequisites

1. **Start ScyllaDB**
   ```bash
   make up          # Single node
   # or
   make up-cluster  # Cluster mode
   ```

2. **Setup Python Environment**
   ```bash
   make setup       # Creates venv and installs dependencies
   source .venv/bin/activate
   ```

3. **Start Jupyter Lab**
   ```bash
   make notebook
   ```

## Notebooks

### 1. Getting Started (`01-getting-started.ipynb`)
**Beginner Level** - Learn the basics of ScyllaDB

Topics:
- Connecting to ScyllaDB
- Creating keyspaces and tables
- Basic CRUD operations (Create, Read, Update, Delete)
- Using prepared statements

Perfect for: First-time users, understanding basic concepts

---

### 2. Advanced Queries (`02-advanced-queries.ipynb`)
**Intermediate Level** - Master advanced query patterns

Topics:
- Time series data with clustering order
- Secondary indexes and their use cases
- Batch operations for performance
- ALLOW FILTERING (and when to avoid it)
- Query performance optimization

Perfect for: Understanding query patterns, performance tuning

---

### 3. Data Modeling (`03-data-modeling.ipynb`)
**Advanced Level** - Learn data modeling best practices

Topics:
- Query-first design approach
- Partition key selection strategies
- Data denormalization patterns
- Collections (lists, sets, maps)
- Counter columns
- One-to-many relationships
- Common patterns and anti-patterns

Perfect for: Designing production schemas, understanding NoSQL principles

---

## Tips for Using the Notebooks

1. **Run cells sequentially** - Each notebook builds on previous cells
2. **Experiment** - Modify queries and see the results
3. **Clean up** - Most notebooks have optional cleanup cells at the end
4. **Check connections** - Make sure ScyllaDB is running before executing cells

## Troubleshooting

### Connection Errors
```python
# Check if ScyllaDB is running
!docker ps | grep scylla

# Check status
!make status
```

### Package Not Found
```bash
# Reinstall dependencies
make install
```

### Kernel Not Found
```bash
# Make sure venv is activated
source .venv/bin/activate

# Install ipykernel
uv pip install ipykernel

# Register kernel
python -m ipykernel install --user --name=scylladb-dev
```

## Additional Resources

- [ScyllaDB Documentation](https://docs.scylladb.com/)
- [CQL Reference](https://docs.scylladb.com/stable/cql/)
- [ScyllaDB University](https://university.scylladb.com/)
- [Cassandra Python Driver Docs](https://docs.datastax.com/en/developer/python-driver/)

## Contributing

Feel free to add your own notebooks or improve existing ones!
