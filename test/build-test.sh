#!/bin/bash

# =============================================================================
# PROMETHEUS STACK ADD-ON - LOCAL TESTING SCRIPT (ADDON MODE)
# =============================================================================
# PURPOSE: Build and run the Home Assistant add-on locally in addon mode
# USAGE:   ./test/build-test.sh (from project root) OR ./build-test.sh (from test folder)
# 
# This script:
# 1. Builds the Docker image with your add-on code
# 2. Creates test configuration data (options.json)
# 3. Runs the container with proper s6-overlay init and Home Assistant environment
# 4. Provides access URLs for testing
#
# REQUIREMENTS: Docker Desktop with WSL2 backend enabled
# =============================================================================

set -e  # Exit on any error

# Determine script location and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "$SCRIPT_DIR" == */test ]]; then
    # Running from test folder
    PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
    TEST_DIR="$SCRIPT_DIR"
else
    # Running from project root
    PROJECT_ROOT="$SCRIPT_DIR"
    TEST_DIR="$SCRIPT_DIR/test"
fi

echo "🐳 Building and Testing Prometheus Stack Add-on"
echo "================================================"
echo " Project root: $PROJECT_ROOT"
echo "📁 Test directory: $TEST_DIR"

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

# Build the add-on image
echo "🔨 Building add-on image..."
cd "$PROJECT_ROOT/prometheus-stack"
docker build -t prometheus-stack-test .

# Create test directories and configuration
echo "📁 Setting up test environment..."
mkdir -p "$PROJECT_ROOT/test-data/prometheus"
mkdir -p "$PROJECT_ROOT/test-data/alertmanager"

# Create test options.json only if it doesn't exist
if [ ! -f "$PROJECT_ROOT/test-data/options.json" ]; then
    echo "📝 Creating default options.json..."
    cat > "$PROJECT_ROOT/test-data/options.json" <<EOF
{
  "alertmanager_receiver": "test-receiver",
  "alertmanager_to_email": "test@example.com",
  "monitor_home_assistant": true,
  "monitor_supervisor": true,
  "monitor_addons": true,
  "custom_targets": [],
  "home_assistant_ip": "192.168.1.30",
  "home_assistant_port": 8123,
  "home_assistant_long_lived_token": "test-token",
  "smtp_host": "localhost",
  "smtp_port": 25
}
EOF
else
    echo "📝 Using existing options.json configuration..."
fi

# Run the container with test configuration (addon mode simulation)
echo "🚀 Starting test container in addon mode..."
docker run -d \
  --name prometheus-stack-test \
  -p 9090:9090 \
  -p 9093:9093 \
  -p 9115:9115 \
  -p 8080:8080 \
  -v "$PROJECT_ROOT/test-data:/data" \
  -e SUPERVISOR_TOKEN="test-supervisor-token" \
  -e HASSIO_TOKEN="test-hassio-token" \
  --entrypoint "/init" \
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
echo "   Prometheus:        http://localhost:9090"
echo "   Alertmanager:      http://localhost:9093"
echo "   Blackbox Exporter: http://localhost:9115"
echo "   Karma UI:          http://localhost:8080"
echo "   NGINX (Ingress):   http://localhost:80"
echo ""
echo "🔍 Health Check URLs:"
echo "   Prometheus:        http://localhost:9090/-/healthy"
echo "   Alertmanager:      http://localhost:9093/-/healthy"
echo "   Blackbox Exporter: http://localhost:9115/metrics"
echo "   Karma:             http://localhost:8080/"
echo "   NGINX:             http://localhost:80/nginx_status"
echo ""
echo "🌐 Ingress Paths:"
echo "   - Karma:           http://localhost:80/"
echo "   - Prometheus:      http://localhost:80/prometheus/"
echo "   - Alertmanager:    http://localhost:80/alertmanager/"
echo "   - Blackbox:        http://localhost:80/blackbox/"
echo ""
echo "🔍 Blackbox Exporter Endpoints:"
echo "   - Metrics:         http://localhost:9115/metrics"
echo "   - Probe Example:   http://localhost:9115/probe?target=google.com&module=http_2xx"
echo "   - Status:          http://localhost:9115/-/healthy"
echo ""
echo "📋 Useful Commands:"
echo "   View logs:      docker logs -f prometheus-stack-test"
echo "   Stop container: docker stop prometheus-stack-test"
echo "   Remove container: docker rm prometheus-stack-test"
echo "   Health check:   $TEST_DIR/health-check.sh"
echo "   Monitor resources: $TEST_DIR/monitor.sh"
echo "   Cleanup:        $TEST_DIR/cleanup.sh"
echo ""
echo "💡 Next Steps:"
echo "   1. Open the URLs above in your browser"
echo "   2. Test the configuration and functionality"
echo "   3. Run health checks to verify everything works"
echo "   4. Use cleanup script when done testing" 