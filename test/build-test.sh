#!/bin/bash

# =============================================================================
# PROMETHEUS STACK ADD-ON - LOCAL TESTING SCRIPT
# =============================================================================
# PURPOSE: Build and run the Home Assistant add-on locally for testing
# USAGE:   ./test/build-test.sh
# 
# This script:
# 1. Builds the Docker image with your add-on code
# 2. Creates test configuration data
# 3. Runs the container with proper port mapping
# 4. Provides access URLs for testing
#
# REQUIREMENTS: Docker Desktop with WSL2 backend enabled
# =============================================================================

set -e  # Exit on any error

echo "🐳 Building and Testing Prometheus Stack Add-on"
echo "================================================"

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Please install Docker Desktop for Windows."
    echo "   Visit: https://docs.docker.com/desktop/install/windows-install/"
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo "❌ Docker is not running. Please start Docker Desktop."
    exit 1
fi

echo "✅ Docker is available and running"

# Clean up any existing test container
echo "🧹 Cleaning up previous test containers..."
docker stop prometheus-stack-test 2>/dev/null || true
docker rm prometheus-stack-test 2>/dev/null || true

# Build the add-on image (from parent directory)
echo "🔨 Building add-on image..."
cd ..
docker build -t prometheus-stack-test .
cd test

# Create test directories and configuration
echo "📁 Setting up test environment..."
mkdir -p ../test-data/prometheus
mkdir -p ../test-data/alertmanager

# Create test options.json (simulates Home Assistant add-on config)
cat > ../test-data/options.json <<EOF
{
  "alertmanager_receiver": "test-receiver",
  "alertmanager_to_email": "test@example.com"
}
EOF

# Run the container with test configuration
echo "🚀 Starting test container..."
docker run -d \
  --name prometheus-stack-test \
  -p 9090:9090 \
  -p 9093:9093 \
  -p 8080:8080 \
  -v $(pwd)/../test-data:/data \
  prometheus-stack-test

# Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 10

# Check if container is running
if docker ps | grep -q prometheus-stack-test; then
    echo "✅ Container is running successfully!"
else
    echo "❌ Container failed to start"
    echo "📋 Container logs:"
    docker logs prometheus-stack-test
    exit 1
fi

echo ""
echo "🎉 Add-on is running and ready for testing!"
echo "============================================="
echo "📊 Service URLs:"
echo "   Prometheus:     http://localhost:9090"
echo "   Alertmanager:   http://localhost:9093"
echo "   Karma UI:       http://localhost:8080"
echo ""
echo "🔍 Health Check URLs:"
echo "   Prometheus:     http://localhost:9090/-/healthy"
echo "   Alertmanager:   http://localhost:9093/-/healthy"
echo "   Karma:          http://localhost:8080/"
echo ""
echo "📋 Useful Commands:"
echo "   View logs:      docker logs -f prometheus-stack-test"
echo "   Stop container: docker stop prometheus-stack-test"
echo "   Remove container: docker rm prometheus-stack-test"
echo "   Health check:   ./test/health-check.sh"
echo "   Monitor resources: ./test/monitor.sh"
echo "   Cleanup:        ./test/cleanup.sh"
echo ""
echo "💡 Next Steps:"
echo "   1. Open the URLs above in your browser"
echo "   2. Test the configuration and functionality"
echo "   3. Run health checks to verify everything works"
echo "   4. Use cleanup script when done testing" 