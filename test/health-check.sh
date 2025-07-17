#!/bin/bash

# =============================================================================
# INFLUXDB STACK ADD-ON - HEALTH CHECK SCRIPT
# =============================================================================
# PURPOSE: Verify that all services in the add-on are running and healthy
# USAGE:   ./test/health-check.sh (from project root) OR ./health-check.sh (from test folder)
# 
# This script performs comprehensive health checks on:
# 1. InfluxDB - Main time-series database
# 2. Grafana - Visualization and alerting platform
# 3. VS Code - Development environment
# 4. NGINX - Ingress routing and load balancing
#
# HEALTH CHECK ENDPOINTS:
# - InfluxDB: /health (built-in health endpoint)
# - Grafana: /api/health (built-in health endpoint)
# - VS Code: / (web interface availability)
# - NGINX: /nginx_status (status endpoint)
#
# RETURN CODES:
# - 0: All services healthy
# - 1: One or more services unhealthy
#
# REQUIREMENTS: Container must be running (use build.sh first)
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
    ["InfluxDB"]="http://localhost:8086/health"
    ["Grafana"]="http://localhost:3000/api/health"
    ["VS Code"]="http://localhost:8443/"
    ["NGINX"]="http://localhost:80/nginx_status"
)

# Configuration files to check
declare -A CONFIG_FILES=(
    ["grafana.ini"]="/etc/grafana/grafana.ini"
    ["influxdb datasource"]="/etc/grafana/provisioning/datasources/influxdb.yml"
    ["ingress.conf"]="/etc/nginx/servers/ingress.conf"
)

# Data directories to check
declare -A DATA_DIRS=(
    ["InfluxDB data"]="/data/influxdb"
    ["Grafana data"]="/data/grafana"
)

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_success() {
    echo -e "${GREEN}$1${NC}"
}

print_error() {
    echo -e "${RED}$1${NC}"
}

print_warning() {
    echo -e "${YELLOW}$1${NC}"
}

print_info() {
    echo -e "${BLUE}$1${NC}"
}

print_final_status() {
    local success="$1"
    echo ""
    if [ "$success" = "true" ]; then
        echo "=================================================="
        print_success "✅ All health checks passed! InfluxDB Stack is healthy ✅"
        echo "=================================================="
        echo ""
        print_info "🎉 Your InfluxDB Stack add-on is ready to use!"
        echo ""
        echo "📊 Quick Access:"
        echo "  • InfluxDB UI:    http://localhost:8086"
        echo "  • Grafana:        http://localhost:3000"
        echo "  • VS Code:        http://localhost:8443"
        echo "  • Main Interface: http://localhost:80"
        echo ""
    else
        echo "=================================================="
        print_error "❌ Health check failed! Some services are unhealthy ❌"
        echo "=================================================="
        echo ""
        print_warning "🔧 Troubleshooting steps:"
        echo "  1. Check container logs: docker logs influxdb-stack-test"
        echo "  2. Restart container: docker restart influxdb-stack-test"
        echo "  3. Rebuild: ./test/build.sh"
        echo ""
    fi
}

# =============================================================================
# HEALTH CHECK FUNCTIONS
# =============================================================================

# Wait for services to be ready
wait_for_services() {
    print_info "⏳ Waiting for services to initialize..."
    
    local max_wait=60
    local wait_count=0
    
    while [ $wait_count -lt $max_wait ]; do
        if curl -s "http://localhost:8086/health" >/dev/null 2>&1; then
            print_success "✅ InfluxDB is responding"
            return 0
        fi
        
        echo -n "."
        sleep 1
        wait_count=$((wait_count + 1))
    done
    
    print_error "❌ Services failed to start within $max_wait seconds"
    return 1
}

# Check individual service health
check_service() {
    local service_name="$1"
    local endpoint="$2"
    
    printf "🔍 Checking %-20s " "$service_name"
    
    local retry_count=0
    while [ $retry_count -lt $MAX_RETRIES ]; do
        if curl -s --max-time $CURL_TIMEOUT "$endpoint" >/dev/null 2>&1; then
            print_success "✅ Healthy"
            return 0
        fi
        
        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $MAX_RETRIES ]; then
            sleep $RETRY_INTERVAL
        fi
    done
    
    print_error "❌ Unhealthy (after $MAX_RETRIES attempts)"
    return 1
}

# Check configuration files
check_config_file() {
    local file_name="$1"
    local file_path="$2"
    
    printf "📄 Checking %-20s " "$file_name"
    
    if docker exec influxdb-stack-test test -f "$file_path" 2>/dev/null; then
        print_success "✅ Found"
        return 0
    else
        print_error "❌ Missing"
        return 1
    fi
}

# Check data directories
check_directory() {
    local dir_path="$1"
    
    printf "📁 Checking %-20s " "$(basename "$dir_path")"
    
    if docker exec influxdb-stack-test test -d "$dir_path" 2>/dev/null; then
        print_success "✅ Exists"
        return 0
    else
        print_error "❌ Missing"
        return 1
    fi
}

# Test service functionality
test_service() {
    local service_name="$1"
    local expected_status="$2"
    printf "🔍 Testing %-30s functionality... " "$service_name"
    
    case "$service_name" in
        "InfluxDB")
            # Test InfluxDB health endpoint
            if curl -s "http://localhost:8086/health" | grep -q '"status":"pass"'; then
                print_success "✅ Health check passed"
                return 0
            else
                print_error "❌ Health check failed"
                return 1
            fi
            ;;
        "Grafana")
            # Test Grafana health endpoint
            if curl -s "http://localhost:3000/api/health" | grep -q '"database":"ok"'; then
                print_success "✅ Database connection working"
                return 0
            else
                print_error "❌ Database connection failed"
                return 1
            fi
            ;;
        "VS Code")
            # Test VS Code accessibility
            if curl -s "http://localhost:8443/" | grep -q -i "vs code\|code-server"; then
                print_success "✅ Server responding"
                return 0
            else
                print_error "❌ Server not responding"
                return 1
            fi
            ;;
        "NGINX")
            # Test NGINX status
            if curl -s "http://localhost:80/nginx_status" | grep -q "Active connections"; then
                print_success "✅ Status page working"
                return 0
            else
                print_error "❌ Status page not working"
                return 1
            fi
            ;;
        "NGINX Proxy Paths")
            # Test NGINX proxy paths
            local paths_ok=true
            
            # Test InfluxDB proxy
            if ! curl -s "http://localhost:80/" | grep -q -i "influxdb\|login"; then
                paths_ok=false
            fi
            
            # Test Grafana proxy
            if ! curl -s "http://localhost:80/grafana/" | grep -q -i "grafana\|login"; then
                paths_ok=false
            fi
            
            if [ "$paths_ok" = "true" ]; then
                print_success "✅ All proxy redirects working"
                return 0
            else
                print_error "❌ Some proxy redirects failed"
                return 1
            fi
            ;;
        *)
            print_error "❌ Unknown service: $service_name"
            return 1
            ;;
    esac
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    echo ""
    echo ""
    echo ""
    echo "🏥  Running Health Check for InfluxDB Stack Add-on"
    echo "================================================="
    echo "📁 Project root: $PROJECT_ROOT"
    echo "📁 Test directory: $TEST_DIR"
    
    # Simple environment detection
    if [ -n "$GITHUB_ACTIONS" ]; then
        echo "🚀 Running in Github-mode"
    else
        echo "🚀 Running in Test-mode"
    fi
    
    # Check if container is running
    if ! docker ps | grep -q influxdb-stack-test; then
        echo ""
        echo "❌ Health check failed: Container 'influxdb-stack-test' is not running ❌"
        print_final_status false
        exit 1
    fi
    echo "✅ Container is running"
    
    # Wait for services to be ready
    if ! wait_for_services; then
        echo "❌ Services failed to start within timeout period"
        print_final_status false
        exit 1
    fi
    
    echo ""
    echo "📊 Performing health checks..."
    echo "-------------------------------"
    
    # Basic health checks
    local health_failed=false
    
    for service in "${!SERVICES[@]}"; do
        if ! check_service "$service" "${SERVICES[$service]}"; then
            health_failed=true
        fi
    done
    
    echo ""
    echo "📋 Checking configuration files..."
    for file in "${!CONFIG_FILES[@]}"; do
        if ! check_config_file "$file" "${CONFIG_FILES[$file]}"; then
            health_failed=true
        fi
    done
    
    echo ""
    echo "📁 Checking data directories..."
    for dir in "${!DATA_DIRS[@]}"; do
        if ! check_directory "${DATA_DIRS[$dir]}"; then
            health_failed=true
        fi
    done
    
    echo ""
    echo "🔬 Testing service functionality..."
    echo "-------------------------------"
    
    # Give services extra time to fully initialize in CI environments
    if [ -n "$GITHUB_ACTIONS" ]; then
        echo "⏳ Github-mode detected - allowing extra time for service initialization..."
        sleep 5
    fi
    
    if ! test_service "InfluxDB" "Health check passed"; then
        health_failed=true
    fi
    
    if ! test_service "Grafana" "Database connection working"; then
        health_failed=true
    fi
    
    if ! test_service "VS Code" "Server responding"; then
        health_failed=true
    fi
    
    if ! test_service "NGINX" "Status page working"; then
        health_failed=true
    fi
    
    if ! test_service "NGINX Proxy Paths" "All proxy redirects working"; then
        health_failed=true
    fi
    
    # Final status
    if [ "$health_failed" = "true" ]; then
        print_final_status false
        exit 1
    else
        print_final_status true
        exit 0
    fi
}

# Error handler
error_handler() {
    print_final_status false
    exit 1
}

# Set up error handling
set -e
trap error_handler ERR

# Get the absolute path of the script directory
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$TEST_DIR/.." && pwd)"

# Run the main function
main 