#!/usr/bin/with-contenv bashio

# =============================================================================
# INFLUXDB STACK SYNC TOOLS - QUICK SSH TEST
# =============================================================================
# PURPOSE: Quick test of SSH connectivity and basic file access
# USAGE:   ./sync-tools/s1_quick-ssh-test.sh
# 
# This script tests:
# 1. SSH connectivity to Home Assistant
# 2. Container detection and access
# 3. Basic file system access for key configuration files
# 4. Service status verification
#
# This is a lightweight test to verify the sync environment before running
# more comprehensive extraction and comparison operations.
# =============================================================================

# Source the configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Load environment and set defaults
load_env
set_defaults

# Detect mode
MODE=$(detect_mode)

print_status() {
    local status="$1"
    local message="$2"
    case $status in
        "OK") echo -e "\033[0;32m✅ $message\033[0m" ;;
        "WARN") echo -e "\033[1;33m⚠️  $message\033[0m" ;;
        "ERROR") echo -e "\033[0;31m❌ $message\033[0m" ;;
        "INFO") echo -e "\033[0;34mℹ️  $message\033[0m" ;;
    esac
}

echo "🔍 InfluxDB Stack Sync Tools - Quick SSH Test"
echo "============================================="
echo "Mode: $MODE"
echo "Container: $(get_container_name "$MODE")"
echo ""

# Test SSH connectivity (addon mode only)
if [ "$MODE" = "addon" ]; then
    print_status "INFO" "Testing SSH connectivity to $HA_HOSTNAME..."
    
    SSH_CMD=$(get_ssh_connection "$MODE")
    if timeout 5 $SSH_CMD "echo 'SSH connection successful'" >/dev/null 2>&1; then
        print_status "OK" "SSH connection to $HA_HOSTNAME working"
    else
        print_status "ERROR" "SSH connection failed to $HA_HOSTNAME"
        exit 1
    fi
else
    print_status "INFO" "Test mode detected - skipping SSH test"
fi

# Test container access
CONTAINER_NAME=$(get_container_name "$MODE")
print_status "INFO" "Testing container access: $CONTAINER_NAME"

if [ "$MODE" = "test" ]; then
    CONTAINER_ID="$CONTAINER_NAME"
else
    SSH_CMD=$(get_ssh_connection "$MODE")
    CONTAINER_ID=$($SSH_CMD "docker ps -q --filter name=$CONTAINER_NAME" 2>/dev/null)
fi

if [ -z "$CONTAINER_ID" ]; then
    print_status "ERROR" "Container $CONTAINER_NAME not found or not running"
    exit 1
fi

print_status "OK" "Container $CONTAINER_NAME is accessible"

# Test file access for key InfluxDB Stack files
echo ""
print_status "INFO" "Testing configuration file access..."

# Create test command based on mode
if [ "$MODE" = "test" ]; then
    TEST_CMD="docker exec $CONTAINER_ID"
else
    SSH_CMD=$(get_ssh_connection "$MODE")
    TEST_CMD="$SSH_CMD docker exec $CONTAINER_ID"
fi

# Test InfluxDB configuration access
echo '  InfluxDB:'
if $TEST_CMD test -d /etc/influxdb 2>/dev/null; then
    echo '    ✅ /etc/influxdb/ directory accessible'
else
    echo '    ❌ /etc/influxdb/ directory not accessible'
fi

# Test Grafana configuration access
echo '  Grafana:'
$TEST_CMD ls /etc/grafana/grafana.ini 2>/dev/null && echo '    ✅ grafana.ini accessible' || echo '    ❌ grafana.ini not accessible'
$TEST_CMD ls /etc/grafana/provisioning/datasources/influxdb.yml 2>/dev/null && echo '    ✅ influxdb.yml datasource accessible' || echo '    ❌ influxdb.yml datasource not accessible'

# Test dashboard access
echo '  Dashboards:'
$TEST_CMD ls /etc/grafana/provisioning/dashboards/ 2>/dev/null && echo '    ✅ Dashboard directory accessible' || echo '    ❌ Dashboard directory not accessible'

# Test NGINX configuration access
echo '  NGINX:'
$TEST_CMD ls /etc/nginx/nginx.conf 2>/dev/null && echo '    ✅ nginx.conf accessible' || echo '    ❌ nginx.conf not accessible'
$TEST_CMD ls /etc/nginx/servers/ingress.conf 2>/dev/null && echo '    ✅ ingress.conf accessible' || echo '    ❌ ingress.conf not accessible'

# Test service status
echo ""
print_status "INFO" "Testing service status..."

# Test InfluxDB service
if $TEST_CMD curl -s http://localhost:8086/health >/dev/null 2>&1; then
    echo '  ✅ InfluxDB service responding'
else
    echo '  ❌ InfluxDB service not responding'
fi

# Test Grafana service
if $TEST_CMD curl -s http://localhost:3000/api/health >/dev/null 2>&1; then
    echo '  ✅ Grafana service responding'
else
    echo '  ❌ Grafana service not responding'
fi

# Test NGINX service
if $TEST_CMD curl -s http://localhost:80/nginx_status >/dev/null 2>&1; then
    echo '  ✅ NGINX service responding'
else
    echo '  ❌ NGINX service not responding'
fi

echo ""
print_status "OK" "Quick SSH test completed successfully"
print_status "INFO" "You can now run the other sync tools:"
print_status "INFO" "  • s2_extract-configs.sh - Extract configurations from container"
print_status "INFO" "  • s3_compare-configs.sh - Compare configurations"
print_status "INFO" "  • s4_sync-to-repo.sh - Sync changes back to repository" 