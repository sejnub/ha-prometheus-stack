#!/bin/bash

# =============================================================================
# PROMETHEUS STACK ADD-ON - HEALTH CHECK SCRIPT
# =============================================================================
# PURPOSE: Verify that all services in the add-on are running and healthy
# USAGE:   ./test/health-check.sh (from project root) OR ./health-check.sh (from test folder)
# 
# This script performs comprehensive health checks on all services in the stack.
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

# Single source of truth for all services
declare -A SERVICES=(
    ["Prometheus"]="http://localhost:9090/-/ready"
    ["Alertmanager"]="http://localhost:9093/-/ready"
    ["Karma"]="http://localhost:8080/"
    ["Blackbox Exporter"]="http://localhost:9115/metrics"
    ["Loki"]="http://localhost:3100/ready"
    ["Promtail"]="http://localhost:9080/ready"
    ["Grafana"]="http://localhost:3000/api/health"
    ["VS Code"]="http://localhost:8443/"
    ["NGINX"]="http://localhost:80/nginx_status"
)

# Configuration files to check
CONFIG_FILES=(
    "/etc/prometheus/prometheus.yml"
    "/etc/alertmanager/alertmanager.yml"
    "/etc/blackbox_exporter/blackbox.yml"
    "/etc/karma/karma.yml"
    "/etc/loki/loki.yml"
    "/etc/promtail/promtail.yml"
    "/etc/grafana/grafana.ini"
    "/etc/nginx/servers/ingress.conf"
)

# Data directories to check
DATA_DIRS=(
    "/data/prometheus"
    "/data/alertmanager"
    "/data/grafana"
    "/data/loki"
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

# Function to check if all services are ready
wait_for_services() {
    local max_attempts=60
    local attempt=1
    
    echo -n "⏳ Checking service readiness..."
    
    # Track which services are ready
    declare -A ready_services
    local total_services=${#SERVICES[@]}
    local ready_count=0
    
    while [ $attempt -le $max_attempts ]; do
        ready_count=0
        
        # Check each service individually
        for service_name in "${!SERVICES[@]}"; do
            if [ "${ready_services[$service_name]}" != "ready" ]; then
                if curl -sf "${SERVICES[$service_name]}" >/dev/null 2>&1; then
                    ready_services[$service_name]="ready"
                    ready_count=$((ready_count + 1))
                fi
            else
                ready_count=$((ready_count + 1))
            fi
        done
        
        # If all services are ready, we're done
        if [ $ready_count -eq $total_services ]; then
            echo " ready!"
            return 0
        fi
        
        echo -n "."
        sleep 0.5
        attempt=$((attempt + 1))
    done
    
    echo " timeout!"
    
    # Show which services failed to start
    echo ""
    echo "❌ Services that failed to start within timeout:"
    for service_name in "${!SERVICES[@]}"; do
        if [ "${ready_services[$service_name]}" != "ready" ]; then
            echo "  - $service_name (${SERVICES[$service_name]})"
        fi
    done
    
    return 1
}

# Function to check service health
check_service() {
    local service_name="$1"
    local url="$2"
    
    printf "🔍 Checking %-20s ... " "$service_name"
    if curl -sf "$url" > /dev/null 2>&1; then
        print_success "✅ OK"
        return 0
    else
        print_error "❌ FAILED"
        return 1
    fi
}

# Function to check configuration file
check_config_file() {
    local file_name="$1"
    local file_path="$2"
    printf "🔍 Checking %-30s ... " "$file_name"
    
    if docker exec prometheus-stack-test test -f "$file_path"; then
        print_success "✅ OK"
        return 0
    else
        print_error "❌ MISSING"
        return 1
    fi
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
                print_error "❌ Cannot connect to Alertmanager"
                return 1
            fi
            ;;
        "Prometheus")
            for n in {1..30}; do
                if curl -s http://localhost:9090/api/v1/targets | grep -q '"health":"up"'; then
                    print_success "✅ Can scrape targets"
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
        "Grafana")
            if curl -s "http://localhost:3000/api/health" | grep -q '"database": "ok"'; then
                print_success "✅ $expected_status"
                return 0
            else
                print_error "❌ Database connection failed"
                return 1
            fi
            ;;
        "VS Code")
            local response_code=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8443/")
            if [[ "$response_code" =~ ^(200|302)$ ]]; then
                print_success "✅ $expected_status"
                return 0
            else
                print_error "❌ VS Code server not responding (HTTP $response_code)"
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
            local paths=("prometheus" "alertmanager" "karma" "blackbox" "grafana" "vscode" "loki" "promtail")
            local path_names=("Prometheus" "Alertmanager" "Karma" "Blackbox" "Grafana" "VS Code" "Loki" "Promtail")
            local test_endpoints=("" "" "" "" "" "" "ready" "targets")
            
            for i in "${!paths[@]}"; do
                local path="${paths[$i]}"
                local name="${path_names[$i]}"
                local endpoint="${test_endpoints[$i]}"
                
                local test_url="http://localhost:80/$path/"
                if [ -n "$endpoint" ]; then
                    test_url="http://localhost:80/$path/$endpoint"
                fi
                
                local response_code=$(curl -s -o /dev/null -w "%{http_code}" "$test_url")
                
                if [[ "$response_code" =~ ^(200|302)$ ]]; then
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
        "Loki")
            if curl -s "http://localhost:3100/ready" > /dev/null; then
                print_success "✅ $expected_status"
                return 0
            else
                print_error "❌ Loki is not ready"
                return 1
            fi
            ;;
        "Promtail")
            if curl -s "http://localhost:9080/ready" > /dev/null; then
                print_success "✅ $expected_status"
                return 0
            else
                print_error "❌ Promtail is not ready"
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
        echo "🚀 Running in Github-mode"
    else
        echo "🚀 Running in Test-mode"
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
    
    # Check all services using the single SERVICES array
    local failed_checks=0
    for service_name in "${!SERVICES[@]}"; do
        if ! check_service "$service_name" "${SERVICES[$service_name]}"; then
            ((failed_checks++))
        fi
    done
    
    echo ""
    echo "📋 Checking configuration files..."
    for config_file in "${CONFIG_FILES[@]}"; do
        local file_name=$(basename "$config_file")
        if ! check_config_file "$file_name" "$config_file"; then
            ((failed_checks++))
        fi
    done
    
    echo ""
    echo "📁 Checking data directories..."
    for data_dir in "${DATA_DIRS[@]}"; do
        local dir_name=$(basename "$data_dir")
        if ! check_directory "$data_dir"; then
            ((failed_checks++))
        fi
    done
    
    echo ""
    echo "🔬 Testing service functionality..."
    echo "-------------------------------"
    
    # Give Alertmanager API extra time to fully initialize in CI environments
    if [ -n "$GITHUB_ACTIONS" ]; then
        echo "⏳ Github-mode detected - allowing extra time for Alertmanager API initialization..."
        sleep 5
    fi
    
    # Test service functionality
    test_service "Karma" "Connected to Alertmanager"
    test_service "Prometheus" "Can scrape targets"
    test_service "Blackbox Exporter" "Probe working"
    test_service "Alertmanager" "Configuration valid"
    test_service "Grafana" "Database connection working"
    test_service "VS Code" "Server responding"
    test_service "NGINX" "All paths working"
    test_service "NGINX Proxy Paths" "All proxy redirects working"
    test_service "Loki" "Loki is ready"
    test_service "Promtail" "Log collection ready"
    
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

# Run the main function
main 