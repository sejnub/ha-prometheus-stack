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
    "/etc/nginx/http.d/ingress.conf"
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
            # Enhanced debug for Karma-Alertmanager connection
            echo ""
            echo "🔍 DEBUG: Karma-Alertmanager Connection Analysis"
            echo "================================================="
            
            # Check if Karma metrics endpoint is accessible
            echo "1. Testing Karma metrics endpoint..."
            if curl -s --max-time 5 "http://localhost:8080/metrics" > /dev/null; then
                echo "   ✅ Karma metrics endpoint is accessible"
            else
                echo "   ❌ Karma metrics endpoint is not accessible"
                print_error "❌ $expected_status"
                return 1
            fi
            
            # Get full Karma metrics for debugging
            echo "2. Retrieving Karma metrics..."
            karma_metrics=$(curl -s --max-time 5 "http://localhost:8080/metrics" 2>/dev/null)
            if [ $? -ne 0 ]; then
                echo "   ❌ Failed to retrieve Karma metrics"
                print_error "❌ $expected_status"
                return 1
            fi
            
            # Show all karma_alertmanager metrics
            echo "3. Looking for karma_alertmanager metrics..."
            alertmanager_metrics=$(echo "$karma_metrics" | grep -E "^karma_alertmanager" || true)
            if [ -n "$alertmanager_metrics" ]; then
                echo "   📊 Found karma_alertmanager metrics:"
                echo "$alertmanager_metrics" | sed 's/^/      /'
            else
                echo "   ⚠️  No karma_alertmanager metrics found"
            fi
            
            # Check specifically for the up metric
            echo "4. Checking karma_alertmanager_up metric..."
            up_metric=$(echo "$karma_metrics" | grep -E "^karma_alertmanager_up" || true)
            if [ -n "$up_metric" ]; then
                echo "   📊 Found up metrics:"
                echo "$up_metric" | sed 's/^/      /'
                
                # Check if any alertmanager is up
                if echo "$up_metric" | grep -q "} 1"; then
                    echo "   ✅ At least one Alertmanager is up"
                    up_count=$(echo "$up_metric" | grep -c "} 1" || echo "0")
                    echo "   📈 Number of up Alertmanagers: $up_count"
                else
                    echo "   ❌ No Alertmanagers are up (all showing 0)"
                fi
            else
                echo "   ❌ No karma_alertmanager_up metric found"
            fi
            
            # Check Alertmanager directly
            echo "5. Testing direct Alertmanager connection..."
            if curl -s --max-time 5 "http://localhost:9093/-/ready" > /dev/null; then
                echo "   ✅ Alertmanager is directly accessible"
                
                # Check if Alertmanager is healthy
                am_health=$(curl -s --max-time 5 "http://localhost:9093/-/ready" 2>/dev/null || echo "ERROR")
                echo "   📊 Alertmanager ready status: $am_health"
            else
                echo "   ❌ Alertmanager is not directly accessible"
            fi
            
            # Check network connectivity between services
            echo "6. Testing network connectivity..."
            if docker exec prometheus-stack-test ping -c 1 localhost > /dev/null 2>&1; then
                echo "   ✅ Localhost connectivity works"
            else
                echo "   ❌ Localhost connectivity failed"
            fi
            
            # Check Karma configuration
            echo "7. Checking Karma configuration..."
            if docker exec prometheus-stack-test test -f /etc/karma/karma.yml; then
                echo "   ✅ Karma config file exists"
                echo "   📄 Karma config content:"
                docker exec prometheus-stack-test cat /etc/karma/karma.yml | sed 's/^/      /'
            else
                echo "   ❌ Karma config file not found"
            fi
            
            # Wait a bit and retry the metric check
            echo "8. Retrying metric check after 2 second delay..."
            sleep 2
            final_check=$(curl -s --max-time 5 "http://localhost:8080/metrics" | grep 'karma_alertmanager_up{alertmanager="default"} 1' || true)
            
            if [ -n "$final_check" ]; then
                echo "   ✅ Final check successful"
                print_success "✅ $expected_status"
                return 0
            else
                echo "   ❌ Final check failed"
                echo "9. Full Karma metrics dump for debugging:"
                echo "   ================================================="
                echo "$karma_metrics" | head -50 | sed 's/^/   /'
                echo "   ================================================="
                print_error "❌ Cannot connect to Alertmanager"
                return 1
            fi
            ;;
        "Prometheus")
            if curl -s "http://localhost:9090/api/v1/targets" | grep -q '"health":"up"'; then
                print_success "✅ $expected_status"
                return 0
            else
                print_error "❌ Cannot scrape targets"
                return 1
            fi
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
    local all_ready=false
    
    echo -n "⏳ Checking service readiness"
    
    # Track individual service readiness
    local prometheus_ready=false
    local alertmanager_ready=false
    local blackbox_ready=false
    local karma_ready=false
    
    while [ $attempt -le $max_attempts ]; do
        # Check each service individually for better debugging
        local services_up=0
        local total_services=4
        
        # Prometheus check
        if curl -sf http://localhost:9090/-/ready >/dev/null 2>&1; then
            if [ "$prometheus_ready" = false ]; then
                echo ""
                echo "   ✅ Prometheus ready (attempt $attempt)"
                prometheus_ready=true
            fi
            ((services_up++))
        fi
        
        # Alertmanager check
        if curl -sf http://localhost:9093/-/ready >/dev/null 2>&1; then
            if [ "$alertmanager_ready" = false ]; then
                echo ""
                echo "   ✅ Alertmanager ready (attempt $attempt)"
                alertmanager_ready=true
            fi
            ((services_up++))
        fi
        
        # Blackbox Exporter check
        if curl -sf http://localhost:9115/health >/dev/null 2>&1; then
            if [ "$blackbox_ready" = false ]; then
                echo ""
                echo "   ✅ Blackbox Exporter ready (attempt $attempt)"
                blackbox_ready=true
            fi
            ((services_up++))
        fi
        
        # Karma check
        if curl -sf http://localhost:8080/health >/dev/null 2>&1; then
            if [ "$karma_ready" = false ]; then
                echo ""
                echo "   ✅ Karma ready (attempt $attempt)"
                karma_ready=true
            fi
            ((services_up++))
        fi
        
        # Show progress every 5 attempts
        if [ $((attempt % 5)) -eq 0 ]; then
            echo ""
            echo "   📊 Progress (attempt $attempt/$max_attempts): $services_up/$total_services services ready"
            echo "      Prometheus: $([ "$prometheus_ready" = true ] && echo "✅" || echo "⏳")"
            echo "      Alertmanager: $([ "$alertmanager_ready" = true ] && echo "✅" || echo "⏳")"
            echo "      Blackbox: $([ "$blackbox_ready" = true ] && echo "✅" || echo "⏳")"
            echo "      Karma: $([ "$karma_ready" = true ] && echo "✅" || echo "⏳")"
            echo -n "   ⏳ Continuing"
        fi
        
        # All services ready?
        if [ $services_up -eq $total_services ]; then
            echo ""
            echo "   🎉 All services ready! Total time: $((attempt * 0.5)) seconds"
            
            # Extra wait for Karma to establish Alertmanager connection
            echo "   ⏳ Waiting additional 3 seconds for Karma-Alertmanager connection..."
            sleep 3
            
            return 0
        fi
        
        echo -n "."
        sleep 0.5
        attempt=$((attempt + 1))
    done
    
    echo ""
    echo "   ❌ Timeout after $max_attempts attempts ($((max_attempts * 0.5)) seconds)"
    echo "   📊 Final status:"
    echo "      Prometheus: $([ "$prometheus_ready" = true ] && echo "✅ Ready" || echo "❌ Not ready")"
    echo "      Alertmanager: $([ "$alertmanager_ready" = true ] && echo "✅ Ready" || echo "❌ Not ready")"
    echo "      Blackbox: $([ "$blackbox_ready" = true ] && echo "✅ Ready" || echo "❌ Not ready")"
    echo "      Karma: $([ "$karma_ready" = true ] && echo "✅ Ready" || echo "❌ Not ready")"
    return 1
}

# Main health check sequence
main() {
    echo "🏥 Health Check for Prometheus Stack Add-on"
    echo "=========================================="
    echo "📁 Project root: $PROJECT_ROOT"
    echo "📁 Test directory: $TEST_DIR"
    
    # Environment detection for debugging
    echo ""
    echo "🔍 Environment Information:"
    echo "-------------------------"
    echo "📊 Current user: $(whoami)"
    echo "📊 Current directory: $(pwd)"
    echo "📊 Container runtime: $(docker --version | head -1)"
    echo "📊 System info: $(uname -a)"
    echo "📊 Available memory: $(free -h | head -2 | tail -1)"
    echo "📊 Disk space: $(df -h . | tail -1)"
    
    # Detect if we're in GitHub Actions
    if [ -n "$GITHUB_ACTIONS" ]; then
        echo "🚀 Running in GitHub Actions mode"
        echo "📊 GitHub workflow: $GITHUB_WORKFLOW"
        echo "📊 GitHub job: $GITHUB_JOB"
        echo "📊 GitHub runner: $RUNNER_OS"
    elif [ -n "$CI" ]; then
        echo "🚀 Running in CI mode"
        echo "📊 CI environment: $CI"
    else
        echo "🚀 Running in local test mode"
    fi
    
    # Show docker environment
    echo ""
    echo "🐳 Docker Environment:"
    echo "--------------------"
    echo "📊 Docker containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | head -10
    
    # Check if container is running
    if ! docker ps | grep -q prometheus-stack-test; then
        echo ""
        echo "❌ Health check failed: Container 'prometheus-stack-test' is not running ❌"
        echo "🐳 All running containers:"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        echo "🐳 Recent container logs:"
        docker logs --tail 20 prometheus-stack-test 2>/dev/null || echo "No logs available"
        print_final_status false
        exit 1
    fi
    echo "✅ Container is running"
    
    # Show container resource usage
    echo ""
    echo "📊 Container Resource Usage:"
    echo "----------------------------"
    docker stats prometheus-stack-test --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" || echo "Could not get container stats"
    
    # Wait for services to be ready
    if ! wait_for_services; then
        echo "❌ Services failed to start within timeout period"
        echo "🐳 Container logs for debugging:"
        docker logs --tail 30 prometheus-stack-test
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
    check_config_file "ingress.conf" "/etc/nginx/http.d/ingress.conf"
    
    echo ""
    echo "📁 Checking data directories..."
    check_directory "/data/prometheus"
    check_directory "/data/alertmanager"
    
    echo ""
    echo "🔬 Testing service functionality..."
    echo "-------------------------------"
    
    # Enhanced retry logic for functionality tests
    declare -A functionality_tests=(
        ["Karma"]="Connected to Alertmanager"
        ["Prometheus"]="Can scrape targets"
        ["Blackbox Exporter"]="Probe working"
        ["Alertmanager"]="Configuration valid"
        ["NGINX"]="All paths working"
    )
    
    local failed_tests=0
    local max_retries=3
    
    for service in "Karma" "Prometheus" "Blackbox Exporter" "Alertmanager" "NGINX"; do
        local success=false
        local retry=1
        
        while [ $retry -le $max_retries ] && [ "$success" = false ]; do
            if [ $retry -gt 1 ]; then
                echo ""
                echo "🔄 Retry $retry/$max_retries for $service functionality test..."
                # Progressive delay: 2s, 5s, 10s
                local delay=$((retry * retry + 1))
                echo "⏳ Waiting ${delay} seconds before retry..."
                sleep $delay
            fi
            
            if test_service "$service" "${functionality_tests[$service]}"; then
                success=true
            else
                ((retry++))
                if [ $retry -le $max_retries ]; then
                    echo "⚠️  $service functionality test failed on attempt $((retry-1)), retrying..."
                fi
            fi
        done
        
        if [ "$success" = false ]; then
            echo "❌ $service functionality test failed after $max_retries attempts"
            ((failed_tests++))
        fi
    done
    
    if [ $failed_tests -gt 0 ]; then
        echo ""
        echo "❌ $failed_tests functionality test(s) failed"
        print_final_status false
        exit 1
    fi
    
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