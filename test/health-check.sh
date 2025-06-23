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

# =============================================================================
# CONFIGURATION
# =============================================================================

# Health check timeout (seconds)
TIMEOUT=10

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
# UTILITY FUNCTIONS
# =============================================================================

# Initialize script environment
init_environment() {
    # Determine script location and project root
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [[ "$SCRIPT_DIR" == */test ]]; then
        PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
        TEST_DIR="$SCRIPT_DIR"
    else
        PROJECT_ROOT="$SCRIPT_DIR"
        TEST_DIR="$SCRIPT_DIR/test"
    fi

    echo "🏥 Health Check for Prometheus Stack Add-on"
    echo "============================================"
    echo "📁 Project root: $PROJECT_ROOT"
    echo "📁 Test directory: $TEST_DIR"
}

# Print formatted status message
print_status() {
    local prefix="$1"
    local message="$2"
    local status="$3"
    printf "%-10s %-40s %s\n" "$prefix" "$message" "$status"
}

# =============================================================================
# CHECK FUNCTIONS
# =============================================================================

# Check if container is running
check_container() {
    if ! docker ps | grep -q prometheus-stack; then
        echo "❌ Container 'prometheus-stack-test' or 'prometheus-stack-dev' is not running"
        echo "   Start the container first with: $TEST_DIR/build-test.sh"
        echo "   Or with docker-compose: docker-compose -f $TEST_DIR/docker-compose.dev.yml up -d"
        return 1
    fi
    echo "✅ Container is running"
    return 0
}

# Check basic service health
check_service_health() {
    local service_name="$1"
    local url="$2"
    
    printf "🔍 Checking %-18s... " "$service_name"
    if curl -f -s --max-time $TIMEOUT "$url" > /dev/null 2>&1; then
        echo "✅ HEALTHY"
        return 0
    else
        echo "❌ UNHEALTHY"
        return 1
    fi
}

# Check service functionality
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
            if curl -s "http://localhost:8080/metrics" | grep -q 'karma_alertmanager_up{alertmanager="default"} 1'; then
                echo "✅ Connected to Alertmanager"
                return 0
            else
                echo "❌ Cannot connect to Alertmanager"
                docker logs prometheus-stack-test 2>&1 | grep -i "karma.*error" || true
                return 1
            fi
            ;;
    esac
}

# Check configuration files
check_config_files() {
    echo ""
    echo "📋 Checking configuration files..."
    local failed=0
    
    for file in "${CONFIG_FILES[@]}"; do
        printf "🔍 Checking %-30s... " "$(basename $file)"
        if docker exec prometheus-stack-test test -r "$file"; then
            echo "✅ OK"
        else
            echo "❌ Missing or unreadable"
            ((failed++))
        fi
    done
    
    return $failed
}

# Check data directories
check_data_directories() {
    echo ""
    echo "📁 Checking data directories..."
    local failed=0
    
    for dir in "${DATA_DIRS[@]}"; do
        printf "🔍 Checking %-30s... " "$dir"
        if docker exec prometheus-stack-test test -w "$dir"; then
            echo "✅ Writable"
        else
            echo "❌ Not writable"
            ((failed++))
        fi
    done
    
    return $failed
}

# Print summary based on check results
print_summary() {
    local failed_checks="$1"
    
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
        return 0
    else
        echo "⚠️  $failed_checks check(s) failed"
        echo ""
        echo "🔧 Troubleshooting:"
        echo "   1. Check container logs: docker logs prometheus-stack-test"
        echo "   2. Verify ports are not in use: netstat -tulpn | grep :9090"
        echo "   3. Restart container: docker restart prometheus-stack-test"
        echo "   4. Check Docker Desktop is running"
        echo ""
        echo "📋 Service Status:"
        for service in "${!SERVICES[@]}"; do
            if curl -f -s --max-time 5 "${SERVICES[$service]}" > /dev/null 2>&1; then
                printf "   ✅ %-18s HEALTHY\n" "$service:"
            else
                printf "   ❌ %-18s UNHEALTHY\n" "$service:"
            fi
        done
        return 1
    fi
}

# =============================================================================
# MAIN SCRIPT
# =============================================================================

main() {
    local failed_checks=0

    # Initialize environment
    init_environment

    # Check container status
    check_container || exit 1

    # Check basic service health
    echo ""
    echo "📊 Performing health checks..."
    echo "-------------------------------"
    for service in "${!SERVICES[@]}"; do
        if ! check_service_health "$service" "${SERVICES[$service]}"; then
            ((failed_checks++))
        fi
    done

    # Check configuration files
    if ! check_config_files; then
        ((failed_checks++))
    fi

    # Check data directories
    if ! check_data_directories; then
        ((failed_checks++))
    fi

    # Check service functionality
    echo ""
    echo "🔬 Testing service functionality..."
    echo "-------------------------------"
    for service in "${!SERVICES[@]}"; do
        if ! check_service_functionality "$service"; then
            ((failed_checks++))
        fi
    done

    # Print summary and exit
    print_summary "$failed_checks"
    exit $?
}

# Run main function
main 