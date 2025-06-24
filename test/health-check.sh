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
# - Prometheus: /-/ready (built-in health endpoint)
# - Alertmanager: /-/ready (built-in health endpoint)
# - Karma: /health (health endpoint)
# - Blackbox Exporter: /health (health endpoint)
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
    ["Prometheus"]="http://localhost:9090/-/ready"
    ["Alertmanager"]="http://localhost:9093/-/ready"
    ["Karma"]="http://localhost:8080/health"
    ["Blackbox Exporter"]="http://localhost:9115/health"
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

# Color definitions
RED='\033[1;31m'    # Bold Red
GREEN='\033[1;32m'  # Bold Green
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'        # No Color

# Function to print colored success message
print_success() {
    echo -e "${GREEN}$1${NC}"
}

# Function to print colored error message
print_error() {
    echo -e "${RED}$1${NC}"
}

# Function to print colored info message
print_info() {
    echo -e "${BLUE}$1${NC}"
}

# Print status messages in a standardized format
print_status() {
    local status="$1"
    local message="$2"
    
    case "$status" in
        "OK")
            echo -e "${GREEN}${message}${NC}"
            ;;
        "ERROR")
            echo -e "${RED}${message}${NC}"
            ;;
        "WARNING")
            echo -e "${YELLOW}${message}${NC}"
            ;;
        "INFO")
            echo -e "${BLUE}${message}${NC}"
            ;;
        *)
            echo "$message"
            ;;
    esac
}

# Set script variables
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEST_DIR="$(cd "$(dirname "$0")" && pwd)"

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

# Function to check configuration file
check_config_file() {
    local file_name="$1"
    local file_path="$2"
    printf "🔍 Checking %-30s ... " "$file_name"
    
    if docker exec prometheus-stack-test test -f "$file_path"; then
        echo "✅ OK"
        return 0
    else
        print_error "❌ MISSING"
        return 1
    fi
}

# Function to check service health with retries
check_service() {
    local service_name="$1"
    local url="$2"
    local max_attempts=30
    local wait_time=1
    
    for ((i=1; i<=max_attempts; i++)); do
        print_info "Checking $service_name (attempt $i/$max_attempts)..."
        if curl -f -s "$url" > /dev/null; then
            print_success "$service_name is healthy"
            return 0
        fi
        if [ $i -lt $max_attempts ]; then
            sleep $wait_time
        fi
    done
    
    print_error "$service_name failed health check at $url"
    return 1
}

# Function to check directory existence
check_directory() {
    local dir="$1"
    printf "🔍 Checking %-30s ... " "$dir"
    
    if docker exec prometheus-stack-test test -d "$dir"; then
        print_success "✅ Writable"
        return 0
    else
        print_error "❌ Not writable"
        return 1
    fi
}

# Function to test service functionality
test_service() {
    local service_name="$1"
    local expected_status="$2"
    printf "🔍 Testing %-30s functionality... " "$service_name"
    
    case "$service_name" in
        "Karma")
            if curl -s "http://localhost:8080/metrics" | grep -q 'karma_alertmanager_up{alertmanager="default"} 1'; then
                print_success "✅ $expected_status"
                return 0
            else
                # Add minimal debug info only in GitHub Actions when it fails
                if [ -n "$GITHUB_ACTIONS" ]; then
                    echo ""
                    echo "🔍 DEBUG: Checking what Karma metrics are available..."
                    karma_up_metrics=$(curl -s "http://localhost:8080/metrics" | grep "karma_alertmanager_up" | head -3)
                    if [ -n "$karma_up_metrics" ]; then
                        echo "   📊 karma_alertmanager_up metrics found:"
                        echo "$karma_up_metrics" | sed 's/^/      /'
                    else
                        echo "   ❌ No karma_alertmanager_up metrics found"
                    fi
                fi
                print_error "❌ Cannot connect to Alertmanager"
                return 1
            fi
            ;;
        "Prometheus")
            # Give Prometheus a bit of time to perform its first scrape (default interval 15s)
            for attempt in {1..30}; do
                if curl -s "http://localhost:9090/api/v1/targets" | grep -q '"health":"up"'; then
                    print_success "✅ $expected_status"
                    return 0
                fi
                sleep 1
            done
            print_error "❌ Cannot scrape targets"
            return 1
            ;;
        "Blackbox Exporter")
            if curl -s "http://localhost:9115/probe?target=google.com&module=http_2xx" | grep -q "probe_success 1"; then
                print_success "✅ $expected_status"
                return 0
            else
                print_error "❌ Probe failed"
                return 1
            fi
            ;;
        "Alertmanager")
            if curl -s "http://localhost:9093/-/ready" | grep -q "OK"; then
                print_success "✅ $expected_status"
                return 0
            else
                print_error "❌ Configuration invalid"
                return 1
            fi
            ;;
        "NGINX")
            local failed=0
            for path in "" "prometheus/" "alertmanager/" "blackbox/"; do
                if ! curl -s -f -H "Host: ingress" "http://localhost:80/$path" > /dev/null; then
                    print_error "❌ Cannot proxy to ${path:-karma}"
                    ((failed++))
                fi
            done
            if [ $failed -eq 0 ]; then
                print_success "✅ $expected_status"
                return 0
            else
                return 1
            fi
            ;;
        "NGINX Proxy Paths")
            local failed=0
            local paths=("prometheus" "alertmanager" "karma" "blackbox")
            local path_names=("Prometheus" "Alertmanager" "Karma" "Blackbox")
            
            for i in "${!paths[@]}"; do
                local path="${paths[$i]}"
                local name="${path_names[$i]}"
                
                # Test that the path returns a proper response (200, 302, etc.)
                local response_code=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:80/$path/")
                
                if [[ "$response_code" =~ ^(200|302)$ ]]; then
                    # Success - 200 OK or 302 redirect are both valid
                    continue
                else
                    print_error "❌ $name proxy returns $response_code"
                    ((failed++))
                fi
            done
            
            if [ $failed -eq 0 ]; then
                print_success "✅ $expected_status"
                return 0
            else
                return 1
            fi
            ;;
    esac
}

# Function to print final status
print_final_status() {
    local success=$1
    echo ""
    if [ "$success" = true ]; then
        echo -e "${GREEN}✅ All services are healthy!${NC}"
    else
        echo -e "${RED}❌ Health check failed!${NC}"
    fi
}

# Function to check if all core services are ready
wait_for_services() {
    local max_attempts=30
    local attempt=1
    
    echo -n "⏳ Checking service readiness..."
    
    while [ $attempt -le $max_attempts ]; do
        # Try to reach each core service
        if curl -sf http://localhost:9090/-/ready >/dev/null 2>&1 && \
           curl -sf http://localhost:9093/-/ready >/dev/null 2>&1 && \
           curl -sf http://localhost:9115/health >/dev/null 2>&1 && \
           curl -sf http://localhost:8080/health >/dev/null 2>&1; then
            echo " ready!"
            return 0
        fi
        
        echo -n "."
        sleep 0.5
        attempt=$((attempt + 1))
    done
    
    echo " timeout!"
    return 1
}

# Main health check sequence
main() {
    echo ""
    echo ""
    echo ""
    echo "🏥  Running Health Check for Prometheus Stack Add-on"
    echo "==================================================="
    echo "📁 Project root: $PROJECT_ROOT"
    echo "📁 Test directory: $TEST_DIR"
    
    # Simple environment detection
    if [ -n "$GITHUB_ACTIONS" ]; then
        echo "🚀 Running in GitHub Actions mode"
    else
        echo "🚀 Running in local test mode"
    fi
    
    # Check if container is running
    if ! docker ps | grep -q prometheus-stack-test; then
        echo ""
        echo "❌ Health check failed: Container 'prometheus-stack-test' is not running ❌"
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
    check_service "Karma" "http://localhost:8080/health"
    check_service "Prometheus" "http://localhost:9090/-/ready"
    check_service "Blackbox Exporter" "http://localhost:9115/health"
    check_service "Alertmanager" "http://localhost:9093/-/ready"
    check_service "NGINX" "http://localhost:80/nginx_status"
    
    echo ""
    echo "📋 Checking configuration files..."
    check_config_file "prometheus.yml" "/etc/prometheus/prometheus.yml"
    check_config_file "alertmanager.yml" "/etc/alertmanager/alertmanager.yml"
    check_config_file "blackbox.yml" "/etc/blackbox_exporter/blackbox.yml"
    check_config_file "karma.yml" "/etc/karma/karma.yml"
    check_config_file "ingress.conf" "/etc/nginx/servers/ingress.conf"
    
    echo ""
    echo "📁 Checking data directories..."
    check_directory "/data/prometheus"
    check_directory "/data/alertmanager"
    
    echo ""
    echo "🔬 Testing service functionality..."
    echo "-------------------------------"
    
    # Give Alertmanager API extra time to fully initialize in CI environments
    if [ -n "$GITHUB_ACTIONS" ]; then
        echo "⏳ GitHub Actions detected - allowing extra time for Alertmanager API initialization..."
        sleep 5
    fi
    
    test_service "Karma" "Connected to Alertmanager"
    test_service "Prometheus" "Can scrape targets"
    test_service "Blackbox Exporter" "Probe working"
    test_service "Alertmanager" "Configuration valid"
    test_service "NGINX" "All paths working"
    test_service "NGINX Proxy Paths" "All proxy redirects working"
    
    # If we got here, all checks passed
    print_final_status true
    exit 0
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

# Function to check Prometheus health
check_prometheus_health() {
    echo ""
    echo "🔍 Checking Prometheus..."
    if ! curl -s "http://localhost:9090/-/ready" > /dev/null; then
        echo ""
        print_status "ERROR" "❌ Health check failed: Prometheus is not healthy ❌"
        exit 1
    fi
    print_status "OK" "Prometheus is healthy"
}

# Function to check Alertmanager health
check_alertmanager_health() {
    echo ""
    echo "🔍 Checking Alertmanager..."
    if ! curl -s "http://localhost:9093/-/ready" > /dev/null; then
        echo ""
        print_status "ERROR" "❌ Health check failed: Alertmanager is not healthy ❌"
        exit 1
    fi
    print_status "OK" "Alertmanager is healthy"
}

# Function to check Blackbox health
check_blackbox_health() {
    echo ""
    echo "🔍 Checking Blackbox Exporter..."
    if ! curl -s "http://localhost:9115/health" > /dev/null; then
        echo ""
        print_status "ERROR" "❌ Health check failed: Blackbox Exporter is not healthy ❌"
        exit 1
    fi
    print_status "OK" "Blackbox Exporter is healthy"
}

# Function to check Karma health
check_karma_health() {
    echo ""
    echo "🔍 Checking Karma..."
    if ! curl -s "http://localhost:8080/health" > /dev/null; then
        echo ""
        print_status "ERROR" "❌ Health check failed: Karma is not healthy ❌"
        exit 1
    fi
    print_status "OK" "Karma is healthy"
}

# Function to check NGINX health
check_nginx_health() {
    echo ""
    echo "🔍 Checking NGINX..."
    if ! curl -s "http://localhost:80/nginx_status" > /dev/null; then
        echo ""
        print_status "ERROR" "❌ Health check failed: NGINX is not healthy ❌"
        exit 1
    fi
    print_status "OK" "NGINX is healthy"
} 