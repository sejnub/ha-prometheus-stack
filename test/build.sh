#!/bin/bash

# =============================================================================
# PROMETHEUS STACK ADD-ON - LOCAL TESTING SCRIPT (TEST-MODE)
# =============================================================================
# PURPOSE: Build and run the Home Assistant add-on locally in Test-mode
# USAGE:   ./test/build.sh (from project root) OR ./build.sh (from test folder)
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

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status="$1"
    local message="$2"
    case $status in
        "OK") echo -e "${GREEN}✅ $message${NC}" ;;
        "WARN") echo -e "${YELLOW}⚠️  $message${NC}" ;;
        "ERROR") echo -e "${RED}❌ $message${NC}" ;;
        "INFO") echo -e "${BLUE}ℹ️  $message${NC}" ;;
    esac
}

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

echo ""
echo ""
echo ""
echo "🐳  Running Build and Testing Prometheus Stack Add-on"
echo "====================================================="
echo " Project root: $PROJECT_ROOT"
echo "📁 Test directory: $TEST_DIR"

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    print_status "ERROR" "❌ Build failed: Docker not installed ❌"
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    print_status "ERROR" "❌ Build failed: Docker not running ❌"
    exit 1
fi

print_status "OK" "Docker is available and running"

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
  "smtp_port": 25,
  "enable_vscode": true,
  "vscode_password": "test123",
  "vscode_workspace": "/config"
}
EOF
fi

# Run the container with test configuration (Test-mode simulation)
echo "🚀 Starting test container in Test-mode..."
docker run -d \
  --name prometheus-stack-test \
  -p 9090:9090 \
  -p 9093:9093 \
  -p 9115:9115 \
  -p 8080:8080 \
  -p 8443:8443 \
  -p 3000:3000 \
  -p 80:80 \
  -v "$PROJECT_ROOT/test-data:/data" \
  -e SUPERVISOR_TOKEN="test-supervisor-token" \
  -e HASSIO_TOKEN="test-hassio-token" \
  --entrypoint "/init" \
  prometheus-stack-test

# Check if container started successfully
if ! docker ps --format '{{.Names}}' | grep -q '^prometheus-stack-test$'; then
    echo "📋 Container logs:"
    docker logs prometheus-stack-test
    echo ""
    print_status "ERROR" "❌ Build failed: Container failed to start ❌"
    exit 1
fi
print_status "OK" "Container started successfully"

echo ""
echo "🎉 Add-on is ready for testing!"
echo "============================================="
echo "📊 Service URLs:"
echo "   Prometheus:        http://localhost:9090"
echo "   Alertmanager:      http://localhost:9093"
echo "   Blackbox Exporter: http://localhost:9115"
echo "   Karma UI:          http://localhost:8080"
echo "   Grafana:           http://localhost:3000"
echo "   VS Code:           http://localhost:8443"
echo "   NGINX (Ingress):   http://localhost:80"
echo ""
echo "🔍 Health Check URLs:"
echo "   Prometheus:        http://localhost:9090/-/healthy"
echo "   Alertmanager:      http://localhost:9093/-/healthy"
echo "   Blackbox Exporter: http://localhost:9115/metrics"
echo "   Karma:             http://localhost:8080/"
echo "   Grafana:           http://localhost:3000/api/health"
echo "   VS Code:           http://localhost:8443/"
echo "   NGINX:             http://localhost:80/nginx_status"
echo ""
echo "🌐 Ingress Paths:"
echo "   - Karma:           http://localhost:80/"
echo "   - Prometheus:      http://localhost:80/prometheus/"
echo "   - Alertmanager:    http://localhost:80/alertmanager/"
echo "   - Blackbox:        http://localhost:80/blackbox/"
echo "   - Grafana:         http://localhost:80/grafana/"
echo "   - VS Code:         http://localhost:80/vscode/"
echo ""
echo "💻 VS Code Access:"
echo "   - Direct:          http://localhost:8443"
echo "   - Ingress:         http://localhost:80/vscode/"
echo "   - Workspace:       /etc"
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
print_status "OK" "✨ Build and test setup completed successfully ✨" 