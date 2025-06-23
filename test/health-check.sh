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
# - Karma: /metrics (metrics endpoint)
# - Blackbox Exporter: /metrics (metrics endpoint)
#
# RETURN CODES:
# - 0: All services healthy
# - 1: One or more services unhealthy
#
# REQUIREMENTS: Container must be running (use build-test.sh first)
# =============================================================================

set -e  # Exit on any error

# =============================================================================
# CONFIGURATION
# =============================================================================

# Health check timeout (seconds)
TIMEOUT=10

# Initial wait time for services to fully start (seconds)
INITIAL_WAIT=30

# Service definitions
declare -A SERVICES=(
    ["Prometheus"]="http://localhost:9090/-/healthy"
    ["Alertmanager"]="http://localhost:9093/-/healthy"
    ["Karma"]="http://localhost:8080/"
    ["Blackbox Exporter"]="http://localhost:9115/metrics"
)

# Configuration files to check
CONFIG_FILES=(
    "/etc/prometheus/prometheus.yml"
    "/etc/alertmanager/alertmanager.yml"
    "/etc/blackbox_exporter/blackbox.yml"
    "/etc/karma/karma.yml"
)

# Data directories to check
DATA_DIRS=(
    "/data/prometheus"
    "/data/alertmanager"
)

# =============================================================================
# FUNCTIONS
# =============================================================================

# Function to check if a service is healthy
check_service() {
    local service_name="$1"
    local url="$2"
    printf "🔍 Checking %-18s ... " "$service_name"
    
    if curl -f -s --max-time $TIMEOUT "$url" > /dev/null; then
        echo "✅ HEALTHY"
        return 0
    else
        echo "❌ UNHEALTHY"
        return 1
    fi
}

# Function to check configuration files
check_config_file() {
    local file="$1"
    printf "🔍 Checking %-30s ... " "$(basename "$file")"
    
    if docker exec prometheus-stack-test test -f "$file"; then
        echo "✅ OK"
        return 0
    else
        echo "❌ MISSING"
        return 1
    fi
}

# Function to check data directory permissions
check_data_dir() {
    local dir="$1"
    printf "🔍 Checking %-30s ... " "$dir"
    
    if docker exec prometheus-stack-test test -w "$dir"; then
        echo "✅ Writable"
        return 0
    else
        echo "❌ Not writable"
        return 1
    fi
}

# Function to check service functionality
check_service_functionality() {
    local service_name="$1"
    printf "🔍 Testing %-18s functionality... " "$service_name"
    
    case "$service_name" in
        "Prometheus")
            if curl -s "http://localhost:9090/api/v1/targets" | grep -q '"health":"up"'; then
                echo "✅ Can scrape targets"
                return 0
            else
                echo "❌ Cannot scrape targets"
                return 1
            fi
            ;;
        "Alertmanager")
            if curl -s "http://localhost:9093/-/ready" | grep -q "OK"; then
                echo "✅ Configuration valid"
                return 0
            else
                echo "❌ Configuration invalid"
                return 1
            fi
            ;;
        "Blackbox Exporter")
            if curl -s "http://localhost:9115/probe?target=google.com&module=http_2xx" | grep -q "probe_success 1"; then
                echo "✅ Probe working"
                return 0
            else
                echo "❌ Probe failed"
                return 1
            fi
            ;;
        "Karma")
            # First check if Karma is running
            if ! curl -f -s --max-time $TIMEOUT "http://localhost:8080/" > /dev/null; then
                echo "❌ Karma UI not accessible"
                return 1
            fi
            
            # Check Alertmanager connection via Karma's metrics
            local metrics
            metrics=$(curl -s "http://localhost:8080/metrics")
            
            # Check if Karma can connect to Alertmanager at all
            if echo "$metrics" | grep -q 'karma_alertmanager_up{alertmanager="default"} 1'; then
                echo "✅ Connected to Alertmanager"
                return 0
            fi
            
            # If not connected, show detailed diagnostics
            echo "❌ Cannot connect to Alertmanager"
            echo "📋 Karma metrics:"
            echo "$metrics" | grep -E "karma_alertmanager_(up|errors)"
            echo "📋 Alertmanager status:"
            curl -s "http://localhost:9093/-/ready" || true
            return 1
            ;;
    esac
}

# =============================================================================
# MAIN SCRIPT
# =============================================================================

echo "🏥 Health Check for Prometheus Stack Add-on"
echo "============================================"
echo "📁 Project root: $(pwd)"
echo "📁 Test directory: $(dirname "$0")"

# Check if container is running
if ! docker ps | grep -q prometheus-stack-test; then
    echo "❌ Container is not running"
    exit 1
fi
echo "✅ Container is running"

# Wait for initial startup
echo "⏳ Waiting $INITIAL_WAIT seconds for services to fully start..."
sleep $INITIAL_WAIT

echo ""
echo "📊 Performing health checks..."
echo "-------------------------------"

# Check basic service health
failed=0
for service in "${!SERVICES[@]}"; do
    if ! check_service "$service" "${SERVICES[$service]}"; then
        ((failed++))
    fi
done

echo ""
echo "📋 Checking configuration files..."
for file in "${CONFIG_FILES[@]}"; do
    if ! check_config_file "$file"; then
        ((failed++))
    fi
done

echo ""
echo "📁 Checking data directories..."
for dir in "${DATA_DIRS[@]}"; do
    if ! check_data_dir "$dir"; then
        ((failed++))
    fi
done

echo ""
echo "🔬 Testing service functionality..."
echo "-------------------------------"
for service in "${!SERVICES[@]}"; do
    if ! check_service_functionality "$service"; then
        ((failed++))
    fi
done

# Final status
echo ""
if [ $failed -eq 0 ]; then
    echo "✅ ALL CHECKS PASSED"
    exit 0
else
    echo "❌ $failed check(s) failed"
    exit 1
fi 