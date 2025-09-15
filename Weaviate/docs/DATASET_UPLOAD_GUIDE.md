# Dataset Upload Guide

This guide explains how to upload JSON datasets to your Weaviate database using the integrated upload tools.

## Quick Start

1. **Setup environment** (first time only):
   ```bash
   make setup
   ```

2. **Start Weaviate**:
   ```bash
   make up              # Single node
   # or
   make up-cluster      # Cluster mode
   ```

3. **Upload dataset**:
   ```bash
   make upload-dataset FILE=your_dataset.json
   ```

## Upload Script Features

### Automatic Schema Creation
- Analyzes JSON structure to infer Weaviate schema
- Creates properties with appropriate data types
- Supports text, int, number, boolean, and array types

### Batch Processing
- Uploads data in configurable batches (default: 100 objects)
- Shows progress during upload
- Handles errors gracefully

### Multi-Node Support
- Works with both single node and cluster deployments
- Can target specific cluster nodes
- Automatic node health checking

## Command Reference

### Makefile Commands

#### Basic Upload
```bash
# Upload to single node (default)
make upload-dataset FILE=dataset.json

# Upload with custom class name
make upload-dataset FILE=dataset.json CLASS=MyClass

# Upload to specific URL
make upload-dataset FILE=dataset.json URL=http://localhost:8081
```

#### Cluster Upload
```bash
# Upload to cluster node 1 (default)
make upload-to-cluster FILE=dataset.json

# Upload to specific cluster node
make upload-to-cluster FILE=dataset.json NODE=2
make upload-to-cluster FILE=dataset.json NODE=3

# Upload with custom class name
make upload-to-cluster FILE=dataset.json CLASS=MyClass NODE=2
```

#### Utilities
```bash
# Check which nodes are accessible
make check-dataset-nodes

# Upload sample dataset
make upload-sample

# Setup environment
make setup

# Install Python dependencies only
make install-deps
```

### Direct Python Script Usage

```bash
# Basic usage
python3 upload_dataset.py dataset.json

# With custom class name
python3 upload_dataset.py dataset.json --class-name ProductCatalog

# Target specific Weaviate instance
python3 upload_dataset.py dataset.json --weaviate-url http://localhost:8081

# Custom batch size
python3 upload_dataset.py dataset.json --batch-size 50

# Skip schema creation (class must exist)
python3 upload_dataset.py dataset.json --no-create-schema

# Check cluster nodes
python3 upload_dataset.py dummy.json --check-cluster
```

## Supported JSON Formats

### Array of Objects (Recommended)
```json
[
  {
    "title": "Article 1",
    "content": "Content here...",
    "tags": ["tag1", "tag2"],
    "rating": 4.5,
    "published": true
  },
  {
    "title": "Article 2",
    "content": "More content...",
    "tags": ["tag3"],
    "rating": 3.8,
    "published": false
  }
]
```

### Single Object (Auto-converted)
```json
{
  "title": "Single Article",
  "content": "Content here...",
  "tags": ["tag1", "tag2"],
  "rating": 4.5,
  "published": true
}
```

## Data Type Mapping

| JSON Type | Weaviate Type | Example |
|-----------|---------------|---------|
| `string` | `text` | `"Hello World"` |
| `number` (int) | `int` | `42` |
| `number` (float) | `number` | `3.14` |
| `boolean` | `boolean` | `true` |
| `array of strings` | `text[]` | `["tag1", "tag2"]` |
| `array of mixed` | `text[]` | `[1, "two", 3]` |

## Schema Creation

### Automatic Schema
The script automatically creates Weaviate classes with:
- **Class name**: Derived from filename or specified via `--class-name`
- **Properties**: Inferred from JSON structure
- **Vectorizer**: `text2vec-ollama` with `nomic-embed-text` model
- **Generative**: `generative-ollama` with `llama3.2` model

### Example Generated Schema
For the sample dataset, this schema is created:
```json
{
  "class": "Articles",
  "properties": [
    {"name": "title", "dataType": ["text"]},
    {"name": "content", "dataType": ["text"]},
    {"name": "category", "dataType": ["text"]},
    {"name": "author", "dataType": ["text"]},
    {"name": "tags", "dataType": ["text[]"]},
    {"name": "difficulty", "dataType": ["text"]},
    {"name": "rating", "dataType": ["number"]}
  ],
  "vectorizer": "text2vec-ollama",
  "moduleConfig": {
    "text2vec-ollama": {
      "apiEndpoint": "http://ollama:11434",
      "model": "nomic-embed-text"
    }
  }
}
```

## Error Handling

### Connection Issues
```bash
Cannot connect to Weaviate at http://localhost:8080
Make sure Weaviate is running:
   Single node: make up-single
   Cluster:     make up-cluster
```

### File Issues
```bash
File not found: dataset.json
Invalid JSON file: Expecting ',' delimiter: line 5 column 10 (char 123)
```

### Upload Issues
```bash
Error creating class MyClass: 422 Client Error
Error uploading batch 1: 500 Server Error
```

## Best Practices

### File Preparation
1. **Validate JSON**: Ensure your JSON is valid
2. **Consistent structure**: All objects should have similar properties
3. **Reasonable size**: Large files are processed in batches automatically

### Performance Tips
1. **Batch size**: Use smaller batches (50-100) for large objects
2. **Network**: Use local Weaviate for faster uploads
3. **Resources**: Ensure sufficient memory for large datasets

### Development Workflow
1. **Start small**: Test with sample data first
2. **Check schema**: Verify the generated schema meets your needs
3. **Monitor logs**: Watch logs during upload for issues
4. **Cluster testing**: Use cluster mode for production scenarios

## Troubleshooting

### Check Service Status
```bash
make status
./switch-mode.sh status
```

### View Logs
```bash
make logs-weaviate
make logs-ollama
```

### Test Connectivity
```bash
make check-dataset-nodes
python3 upload_dataset.py dummy.json --check-cluster
```

### Restart Services
```bash
make restart
# or
make clean && make up
```

## Examples

### E-commerce Product Catalog
```bash
# Upload product data to cluster node 2
make upload-to-cluster FILE=products.json CLASS=ProductCatalog NODE=2
```

### Research Articles
```bash
# Upload with custom batch size for large articles
python3 upload_dataset.py articles.json --class-name Research --batch-size 25
```

### User Reviews
```bash
# Upload to specific instance
make upload-dataset FILE=reviews.json CLASS=UserReviews URL=http://localhost:8081
```
