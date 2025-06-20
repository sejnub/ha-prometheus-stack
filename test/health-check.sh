#!/bin/bash

# =============================================================================
# PROMETHEUS STACK ADD-ON - HEALTH CHECK SCRIPT
# =============================================================================
# PURPOSE: Verify that all services in the add-on are running and healthy
# USAGE:   ./test/health-check.sh (from project root) OR ./health-check.sh (from test folder)
# 
# This script performs comprehensive health checks on:
# 1. Prometheus - Main monitoring service
# 2. Alertmanager - Alert routing and notification service  
# 3. Karma - Alert dashboard and management interface
# 4. Blackbox Exporter - External service monitoring
#
# HEALTH CHECK ENDPOINTS:
# - Prometheus: /-/healthy (built-in health endpoint)
# - Alertmanager: /-/healthy (built-in health endpoint)
# - Karma: / (web interface availability)
# - Blackbox Exporter: /metrics (metrics endpoint)
#
# RETURN CODES:
# - 0: All services healthy
# - 1: One or more services unhealthy
#
# REQUIREMENTS: Container must be running (use build-test.sh first)
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

echo "🏥 Health Check for Prometheus Stack Add-on"
echo "============================================"
echo "📁 Project root: $PROJECT_ROOT"
echo "📁 Test directory: $TEST_DIR"

# Check if container is running
if ! docker ps | grep -q prometheus-stack; then
    echo "❌ Container 'prometheus-stack-test' or 'prometheus-stack-dev' is not running"
    echo "   Start the container first with: $TEST_DIR/build-test.sh"
    echo "   Or with docker-compose: docker-compose -f $TEST_DIR/docker-compose.dev.yml up -d"
    exit 1
fi

echo "✅ Container is running"

# Define services to check
declare -A services=(
    ["Prometheus"]="http://localhost:9090/-/healthy"
    ["Alertmanager"]="http://localhost:9093/-/healthy"
    ["Karma"]="http://localhost:8080/"
    ["Blackbox Exporter"]="http://localhost:9115/metrics"
)

# Health check timeout (seconds)
TIMEOUT=10

# Function to check service health
check_service() {
    local service_name="$1"
    local url="$2"
    
    printf "🔍 Checking %-18s... " "$service_name"
    
    # Use curl with timeout and follow redirects
    if curl -f -s --max-time $TIMEOUT "$url" > /dev/null 2>&1; then
        echo "✅ HEALTHY"
        return 0
    else
        echo "❌ UNHEALTHY"
        return 1
    fi
}

# Perform health checks
echo ""
echo "📊 Performing health checks..."
echo "-------------------------------"

failed_checks=0

for service in "${!services[@]}"; do
    if ! check_service "$service" "${services[$service]}"; then
        ((failed_checks++))
    fi
done

echo ""
echo "📋 Health Check Summary"
echo "======================="

if [ $failed_checks -eq 0 ]; then
    echo "🎉 ALL SERVICES ARE HEALTHY!"
    echo ""
    printf "✅ %-18s http://localhost:9090\n" "Prometheus:"
    printf "✅ %-18s http://localhost:9093\n" "Alertmanager:"
    printf "✅ %-18s http://localhost:8080\n" "Karma:"
    printf "✅ %-18s http://localhost:9115\n" "Blackbox Exporter:"
    echo ""
    echo "💡 Your add-on is ready for use!"
    echo ""
    echo "🔍 Blackbox Exporter Endpoints:"
    echo "   - Metrics:         http://localhost:9115/metrics"
    echo "   - Probe Example:   http://localhost:9115/probe?target=google.com&module=http_2xx"
    echo "   - Status:          http://localhost:9115/-/healthy"
    exit 0
else
    echo "⚠️  $failed_checks service(s) are unhealthy"
    echo ""
    echo "🔧 Troubleshooting:"
    echo "   1. Check container logs: docker logs prometheus-stack-test"
    echo "   2. Verify ports are not in use: netstat -tulpn | grep :9090"
    echo "   3. Restart container: docker restart prometheus-stack-test"
    echo "   4. Check Docker Desktop is running"
    echo ""
    echo "📋 Service Status:"
    for service in "${!services[@]}"; do
        if curl -f -s --max-time 5 "${services[$service]}" > /dev/null 2>&1; then
            printf "   ✅ %-18s HEALTHY\n" "$service:"
        else
            printf "   ❌ %-18s UNHEALTHY\n" "$service:"
        fi
    done
    exit 1
fi 