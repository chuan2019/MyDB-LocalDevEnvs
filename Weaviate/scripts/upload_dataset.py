#!/usr/bin/env python3
"""
Weaviate Dataset Upload Script

This script uploads JSON datasets to a Weaviate database.
Supports both single node and cluster mode configurations.
"""

import json
import argparse
import sys
import os
import time
from pathlib import Path
from typing import Dict, List, Any, Optional
import requests


class WeaviateUploader:
    def __init__(self, weaviate_url: str = "http://localhost:8080"):
        self.weaviate_url = weaviate_url.rstrip('/')
        self.session = requests.Session()
        
    def check_connection(self) -> bool:
        """Check if Weaviate is accessible"""
        try:
            response = self.session.get(f"{self.weaviate_url}/v1/meta", timeout=5)
            return response.status_code == 200
        except requests.exceptions.RequestException:
            return False
    
    def get_schema(self) -> Dict[str, Any]:
        """Get current Weaviate schema"""
        try:
            response = self.session.get(f"{self.weaviate_url}/v1/schema")
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"❌ Error getting schema: {e}")
            return {}
    
    def create_class(self, class_name: str, properties: List[Dict[str, Any]]) -> bool:
        """Create a new class in Weaviate schema"""
        class_definition = {
            "class": class_name,
            "description": f"Auto-generated class for {class_name} dataset",
            "properties": properties,
            "vectorizer": "text2vec-ollama",
            "moduleConfig": {
                "text2vec-ollama": {
                    "apiEndpoint": "http://ollama:11434",
                    "model": "nomic-embed-text"
                },
                "generative-ollama": {
                    "apiEndpoint": "http://ollama:11434", 
                    "model": "llama3.2"
                }
            }
        }

        try:
            response = self.session.post(
                f"{self.weaviate_url}/v1/schema",
                json=class_definition,
                headers={"Content-Type": "application/json"}
            )
            response.raise_for_status()
            print(f"✅ Created class: {class_name}")
            return True
        except requests.exceptions.RequestException as e:
            print(f"❌ Error creating class {class_name}: {e}")
            if hasattr(e, 'response') and e.response is not None:
                print(f"Response: {e.response.text}")
            return False
    
    def infer_property_type(self, value: Any) -> str:
        """Infer Weaviate property type from value"""
        if isinstance(value, bool):
            return "boolean"
        elif isinstance(value, int):
            return "int"
        elif isinstance(value, float):
            return "number"
        elif isinstance(value, list):
            if value and isinstance(value[0], str):
                return "text[]"
            else:
                return "text[]"  # Default to text array
        else:
            return "text"
    
    def analyze_json_structure(self, data: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Analyze JSON data structure to infer schema properties"""
        if not data:
            return []
        
        # Get all unique keys from all objects
        all_keys = set()
        for item in data:
            all_keys.update(item.keys())
        
        properties = []
        for key in sorted(all_keys):
            # Find first non-null value for this key to infer type
            sample_value = None
            for item in data:
                if key in item and item[key] is not None:
                    sample_value = item[key]
                    break
            
            if sample_value is not None:
                prop_type = self.infer_property_type(sample_value)
                properties.append({
                    "name": key,
                    "dataType": [prop_type],
                    "description": f"Auto-generated property for {key}"
                })
        
        return properties
    
    def upload_objects(self, class_name: str, objects: List[Dict[str, Any]], batch_size: int = 100) -> bool:
        """Upload objects to Weaviate in batches"""
        total_objects = len(objects)
        successful_uploads = 0
        
        print(f"📤 Uploading {total_objects} objects in batches of {batch_size}...")
        
        for i in range(0, total_objects, batch_size):
            batch = objects[i:i + batch_size]
            batch_data = {
                "objects": [
                    {
                        "class": class_name,
                        "properties": obj
                    }
                    for obj in batch
                ]
            }
            
            try:
                response = self.session.post(
                    f"{self.weaviate_url}/v1/batch/objects",
                    json=batch_data,
                    headers={"Content-Type": "application/json"}
                )
                response.raise_for_status()
                
                # Check batch results
                result = response.json()
                if isinstance(result, list):
                    batch_successful = sum(1 for item in result if item.get("result", {}).get("status") == "SUCCESS")
                    successful_uploads += batch_successful
                    print(f"📦 Batch {i//batch_size + 1}: {batch_successful}/{len(batch)} objects uploaded")
                else:
                    successful_uploads += len(batch)
                    print(f"📦 Batch {i//batch_size + 1}: {len(batch)} objects uploaded")
                
            except requests.exceptions.RequestException as e:
                print(f"❌ Error uploading batch {i//batch_size + 1}: {e}")
                if hasattr(e, 'response') and e.response is not None:
                    print(f"Response: {e.response.text}")
        
        print(f"✅ Upload completed: {successful_uploads}/{total_objects} objects successfully uploaded")
        return successful_uploads == total_objects
    
    def upload_dataset(self, file_path: str, class_name: Optional[str] = None, 
                      create_schema: bool = True, batch_size: int = 100) -> bool:
        """Upload a JSON dataset to Weaviate"""
        # Validate file
        if not os.path.exists(file_path):
            print(f"❌ File not found: {file_path}")
            return False
        
        # Generate class name if not provided
        if not class_name:
            class_name = Path(file_path).stem.replace('-', '_').replace(' ', '_')
            class_name = ''.join(word.capitalize() for word in class_name.split('_'))
        
        print(f"📂 Loading dataset from: {file_path}")
        print(f"🏷️  Using class name: {class_name}")
        
        # Load JSON data
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
                
            # Ensure data is a list
            if isinstance(data, dict):
                data = [data]
            elif not isinstance(data, list):
                print(f"❌ Unsupported data format. Expected list or dict, got {type(data)}")
                return False
                
            print(f"📊 Loaded {len(data)} objects")
            
        except json.JSONDecodeError as e:
            print(f"❌ Invalid JSON file: {e}")
            return False
        except Exception as e:
            print(f"❌ Error reading file: {e}")
            return False
        
        # Check if class already exists
        schema = self.get_schema()
        existing_classes = [cls['class'] for cls in schema.get('classes', [])]
        
        if class_name in existing_classes:
            print(f"ℹ️  Class '{class_name}' already exists")
            if create_schema:
                response = input(f"Do you want to continue uploading to existing class? (y/N): ")
                if response.lower() != 'y':
                    print("❌ Upload cancelled")
                    return False
        else:
            if create_schema:
                print(f"🔍 Analyzing data structure...")
                properties = self.analyze_json_structure(data)
                print(f"📋 Inferred {len(properties)} properties")
                
                if not self.create_class(class_name, properties):
                    return False
            else:
                print(f"❌ Class '{class_name}' does not exist and schema creation is disabled")
                return False
        
        # Upload data
        return self.upload_objects(class_name, data, batch_size)


def main():
    parser = argparse.ArgumentParser(
        description="Upload JSON datasets to Weaviate database",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s dataset.json
  %(prog)s dataset.json --class-name MyData
  %(prog)s dataset.json --weaviate-url http://localhost:8081
  %(prog)s dataset.json --no-create-schema --batch-size 50
        """
    )
    
    parser.add_argument(
        'file_path',
        help='Path to the JSON dataset file'
    )
    
    parser.add_argument(
        '--class-name',
        help='Weaviate class name (auto-generated from filename if not provided)'
    )
    
    parser.add_argument(
        '--weaviate-url',
        default='http://localhost:8080',
        help='Weaviate instance URL (default: http://localhost:8080)'
    )
    
    parser.add_argument(
        '--batch-size',
        type=int,
        default=100,
        help='Upload batch size (default: 100)'
    )
    
    parser.add_argument(
        '--no-create-schema',
        action='store_true',
        help='Do not create schema automatically (class must exist)'
    )
    
    parser.add_argument(
        '--check-cluster',
        action='store_true',
        help='Check all cluster nodes (ports 8080-8082)'
    )
    
    args = parser.parse_args()
    
    # Check cluster if requested
    if args.check_cluster:
        print("🔍 Checking cluster nodes...")
        for port in [8080, 8081, 8082]:
            url = f"http://localhost:{port}"
            uploader = WeaviateUploader(url)
            if uploader.check_connection():
                print(f"✅ Node at {url} is accessible")
            else:
                print(f"❌ Node at {url} is not accessible")
        return
    
    # Initialize uploader
    uploader = WeaviateUploader(args.weaviate_url)
    
    # Check connection
    print(f"🔗 Connecting to Weaviate at {args.weaviate_url}...")
    if not uploader.check_connection():
        print(f"❌ Cannot connect to Weaviate at {args.weaviate_url}")
        print("💡 Make sure Weaviate is running:")
        print("   Single node: make up-single")
        print("   Cluster:     make up-cluster")
        sys.exit(1)
    
    print("✅ Connected to Weaviate")
    
    # Upload dataset
    success = uploader.upload_dataset(
        file_path=args.file_path,
        class_name=args.class_name,
        create_schema=not args.no_create_schema,
        batch_size=args.batch_size
    )
    
    if success:
        print("🎉 Dataset upload completed successfully!")
        print(f"🔗 Access Weaviate at: {args.weaviate_url}")
    else:
        print("❌ Dataset upload failed!")
        sys.exit(1)


if __name__ == "__main__":
    main()
