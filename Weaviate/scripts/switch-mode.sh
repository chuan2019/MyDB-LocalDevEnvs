#!/bin/bash

# Weaviate Mode Switcher Script
# Usage: ./switch-mode.sh [single|cluster]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

show_help() {
    echo "🔧 Weaviate Local Development Mode Switcher"
    echo ""
    echo "Usage: $0 [mode]"
    echo ""
    echo "Modes:"
    echo "  single   - Single node Weaviate (default)"
    echo "  cluster  - 3-node Weaviate cluster"
    echo "  status   - Show current status"
    echo "  help     - Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 single          # Switch to single node mode"
    echo "  $0 cluster         # Switch to cluster mode"
    echo "  $0 status          # Show what's currently running"
    echo ""
    echo "Direct Make commands:"
    echo "  make up-single     # Start single node"
    echo "  make up-cluster    # Start cluster"
    echo "  make down          # Stop all"
    echo "  make help          # Full help"
}

check_status() {
    echo "📊 Current Status:"
    echo ""
    
    # Check if single node is running
    if docker ps --format "table {{.Names}}" | grep -q "weaviate-single"; then
        echo "✅ Single node mode is ACTIVE"
        echo "   🔗 Weaviate: http://localhost:8080"
    else
        echo "❌ Single node mode is INACTIVE"
    fi
    
    echo ""
    
    # Check if cluster is running
    cluster_nodes=$(docker ps --format "table {{.Names}}" | grep "weaviate-node" | wc -l)
    if [ "$cluster_nodes" -gt 0 ]; then
        echo "✅ Cluster mode is ACTIVE ($cluster_nodes/3 nodes)"
        echo "   🔗 Node 1: http://localhost:8080"
        echo "   🔗 Node 2: http://localhost:8081"
        echo "   🔗 Node 3: http://localhost:8082"
    else
        echo "❌ Cluster mode is INACTIVE"
    fi
    
    echo ""
    
    # Check Ollama
    if docker ps --format "table {{.Names}}" | grep -q "ollama"; then
        echo "✅ Ollama is ACTIVE"
        echo "   🔗 Ollama: http://localhost:11435"
    else
        echo "❌ Ollama is INACTIVE"
    fi
}

switch_to_single() {
    echo "🔄 Switching to single node mode..."
    echo ""
    
    # Stop any running services
    echo "🛑 Stopping any running services..."
    make down > /dev/null 2>&1 || true
    
    echo "🚀 Starting single node mode..."
    make up-single
    
    echo ""
    echo "✅ Successfully switched to single node mode!"
    echo "🔗 Weaviate: http://localhost:8080"
    echo "🔗 Ollama: http://localhost:11435"
}

switch_to_cluster() {
    echo "🔄 Switching to cluster mode..."
    echo ""
    
    # Stop any running services
    echo "🛑 Stopping any running services..."
    make down > /dev/null 2>&1 || true
    
    echo "🚀 Starting cluster mode..."
    make up-cluster
    
    echo ""
    echo "✅ Successfully switched to cluster mode!"
    echo "🔗 Node 1: http://localhost:8080"
    echo "🔗 Node 2: http://localhost:8081"
    echo "🔗 Node 3: http://localhost:8082"
    echo "🔗 Ollama: http://localhost:11435"
    echo ""
    echo "💡 You can connect to any node - the cluster will distribute requests automatically"
}

# Main logic
case "${1:-status}" in
    "single")
        switch_to_single
        ;;
    "cluster")
        switch_to_cluster
        ;;
    "status")
        check_status
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        echo "❌ Unknown mode: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
