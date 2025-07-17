#!/bin/bash

# =============================================================================
# INFLUXDB STACK ADD-ON - LOCAL TESTING SCRIPT (TEST-MODE)
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
echo "🐳  Running Build and Testing InfluxDB Stack Add-on"
echo "=================================================="
echo " Project root: $PROJECT_ROOT"
echo "📁 Test directory: $TEST_DIR"

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    print_status "ERROR" "❌ Build failed: Docker not installed ❌"
    exit 1
fi

# Variables
CONTAINER_NAME="influxdb-stack-test"
IMAGE_NAME="influxdb-stack-test"
ADDON_DIR="$PROJECT_ROOT/influxdb-stack"
TEST_DATA_DIR="$TEST_DIR/test-data"

# Check if addon directory exists
if [ ! -d "$ADDON_DIR" ]; then
    print_status "ERROR" "❌ Build failed: Add-on directory not found: $ADDON_DIR ❌"
    exit 1
fi

print_status "INFO" "📦 Building Docker image..."
print_status "INFO" "📁 Add-on directory: $ADDON_DIR"

# Build the Docker image
cd "$ADDON_DIR"
if ! docker build -t "$IMAGE_NAME" .; then
    print_status "ERROR" "❌ Build failed: Docker build failed ❌"
    exit 1
fi

print_status "OK" "✅ Docker image built successfully"

# Create test data directory
mkdir -p "$TEST_DATA_DIR"

# Create or update test configuration
OPTIONS_FILE="$TEST_DATA_DIR/options.json"
if [ ! -f "$OPTIONS_FILE" ]; then
    print_status "INFO" "📝 Creating test configuration..."
    cat > "$OPTIONS_FILE" <<EOF
{
  "influxdb_org": "test-org",
  "influxdb_bucket": "test-bucket",
  "influxdb_username": "admin",
  "influxdb_password": "testpass123",
  "influxdb_token": "",
  "home_assistant_url": "http://supervisor/core",
  "home_assistant_token": "your-long-lived-access-token-here",
  "enable_vscode": true,
  "vscode_password": "testpass",
  "vscode_workspace": "/config",
  "grafana_admin_password": "testpass"
}
EOF
    print_status "OK" "✅ Test configuration created"
else
    print_status "INFO" "📝 Using existing test configuration"
fi

# Stop and remove existing container if it exists
if docker ps -a --filter "name=$CONTAINER_NAME" | grep -q "$CONTAINER_NAME"; then
    print_status "INFO" "🛑 Stopping existing container..."
    docker stop "$CONTAINER_NAME" >/dev/null 2>&1 || true
    docker rm "$CONTAINER_NAME" >/dev/null 2>&1 || true
fi

# Run the container
print_status "INFO" "🚀 Starting container..."
docker run -d \
    --name "$CONTAINER_NAME" \
     \
    -p 8086:8086 \
    -p 3000:3000 \
    -p 8443:8443 \
    -p 80:80 \
    -v "$TEST_DATA_DIR:/data" \
    -e "TZ=UTC" \
    "$IMAGE_NAME"

# Wait for container to start
sleep 5

# Check if container is running
if ! docker ps --filter "name=$CONTAINER_NAME" | grep -q "$CONTAINER_NAME"; then
    print_status "ERROR" "❌ Container failed to start"
    docker logs "$CONTAINER_NAME"
    exit 1
fi

print_status "OK" "✅ Container started successfully"

echo ""
echo "🎉 InfluxDB Stack Add-on is now running!"
echo "========================================="
echo ""
echo "📊 Access URLs:"
echo "  • InfluxDB UI:    http://localhost:8086"
echo "  • Grafana:        http://localhost:3000"
echo "  • VS Code:        http://localhost:8443"
echo "  • Main Interface: http://localhost:80"
echo ""
echo "🔧 Management:"
echo "  • View logs:      docker logs $CONTAINER_NAME"
echo "  • Stop container: docker stop $CONTAINER_NAME"
echo "  • Restart:        docker restart $CONTAINER_NAME"
echo ""
echo "📁 Test data directory: $TEST_DATA_DIR"
echo "📝 Configuration file: $OPTIONS_FILE"
echo ""
echo "🏥 Health check: Run ./test/health-check.sh to verify all services"
echo "" 