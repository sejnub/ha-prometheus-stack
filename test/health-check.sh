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
# 5. NGINX - Ingress routing and path handling
#
# HEALTH CHECK ENDPOINTS:
# - Prometheus: /-/healthy (built-in health endpoint)
# - Alertmanager: /-/healthy (built-in health endpoint)
# - Karma: /metrics (metrics endpoint)
# - Blackbox Exporter: /metrics (metrics endpoint)
# - NGINX: /nginx_status (status endpoint)
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

# Maximum number of retries for each check
MAX_RETRIES=5
# Interval between retries in seconds
RETRY_INTERVAL=1
# Timeout for individual curl requests
CURL_TIMEOUT=2

# Service definitions with their health check endpoints
declare -A SERVICES=(
    ["Prometheus"]="http://localhost:9090/-/healthy"
    ["Alertmanager"]="http://localhost:9093/-/healthy"
    ["Karma"]="http://localhost:8080/"
    ["Blackbox Exporter"]="http://localhost:9115/metrics"
    ["NGINX"]="http://localhost:80/nginx_status"
)

# Configuration files to check
CONFIG_FILES=(
    "/etc/prometheus/prometheus.yml"
    "/etc/alertmanager/alertmanager.yml"
    "/etc/blackbox_exporter/blackbox.yml"
    "/etc/karma/karma.yml"
    "/etc/nginx/servers/ingress.conf"
)

# Data directories to check
DATA_DIRS=(
    "/data/prometheus"
    "/data/alertmanager"
)

# =============================================================================
# FUNCTIONS
# =============================================================================

# Function to perform retried checks
retry_check() {
    local check_name="$1"
    local check_command="$2"
    local attempt=1
    
    while [ $attempt -le $MAX_RETRIES ]; do
        if eval "$check_command"; then
            return 0
        fi
        if [ $attempt -lt $MAX_RETRIES ]; then
            echo "⏳ Retry $attempt/$MAX_RETRIES for $check_name..."
            sleep $RETRY_INTERVAL
        fi
        ((attempt++))
    done
    return 1
}

# Function to check if a service is healthy
check_service() {
    local service_name="$1"
    local url="$2"
    printf "🔍 Checking %-18s ... " "$service_name"
    
    if retry_check "$service_name" "curl -f -s --max-time $CURL_TIMEOUT '$url' > /dev/null"; then
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
            if retry_check "Prometheus targets" "curl -s 'http://localhost:9090/api/v1/targets' | grep -q '\"health\":\"up\"'"; then
                echo "✅ Can scrape targets"
                return 0
            else
                echo "❌ Cannot scrape targets"
                return 1
            fi
            ;;
        "Alertmanager")
            if retry_check "Alertmanager config" "curl -s 'http://localhost:9093/-/ready' | grep -q 'OK'"; then
                echo "✅ Configuration valid"
                return 0
            else
                echo "❌ Configuration invalid"
                return 1
            fi
            ;;
        "Blackbox Exporter")
            if retry_check "Blackbox probe" "curl -s 'http://localhost:9115/probe?target=google.com&module=http_2xx' | grep -q 'probe_success 1'"; then
                echo "✅ Probe working"
                return 0
            else
                echo "❌ Probe failed"
                return 1
            fi
            ;;
        "Karma")
            # Check if Karma is running and can connect to Alertmanager
            if retry_check "Karma Alertmanager connection" "curl -s 'http://localhost:8080/metrics' | grep -q 'karma_alertmanager_up{alertmanager=\"default\"} 1'"; then
                echo "✅ Connected to Alertmanager"
                return 0
            else
                echo "❌ Cannot connect to Alertmanager"
                echo "📋 Karma metrics:"
                curl -s "http://localhost:8080/metrics" | grep -E "karma_alertmanager_(up|errors)" || true
                echo "📋 Alertmanager status:"
                curl -s "http://localhost:9093/-/ready" || true
                return 1
            fi
            ;;
        "NGINX")
            # Check if NGINX can proxy requests to all services
            local failed=0
            for path in "" "prometheus/" "alertmanager/" "blackbox/"; do
                if ! retry_check "NGINX proxy to ${path:-karma}" "curl -s -f -H 'Host: ingress' http://localhost:80/$path > /dev/null"; then
                    echo "❌ Cannot proxy to ${path:-karma}"
                    ((failed++))
                fi
            done
            if [ $failed -eq 0 ]; then
                echo "✅ All paths working"
                return 0
            else
                return 1
            fi
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

# Initial quick check for basic container readiness
echo "⏳ Waiting for services to start..."
if ! retry_check "basic container readiness" "docker exec prometheus-stack-test ps aux | grep -q prometheus"; then
    echo "❌ Container services failed to start"
    exit 1
fi

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

# Continue with configuration checks
echo ""
echo "📋 Checking configuration files..."
for file in "${CONFIG_FILES[@]}"; do
    if ! check_config_file "$file"; then
        ((failed++))
    fi
done

# Check data directories
echo ""
echo "📁 Checking data directories..."
for dir in "${DATA_DIRS[@]}"; do
    if ! check_data_dir "$dir"; then
        ((failed++))
    fi
done

# Check service functionality
echo ""
echo "🔬 Testing service functionality..."
echo "-------------------------------"
for service in "${!SERVICES[@]}"; do
    if ! check_service_functionality "$service"; then
        ((failed++))
    fi
done

# Final result
if [ $failed -eq 0 ]; then
    echo ""
    echo "✅ ALL CHECKS PASSED"
    echo "✅ All services are healthy!"
    exit 0
else
    echo ""
    echo "❌ $failed checks failed"
    exit 1
fi 