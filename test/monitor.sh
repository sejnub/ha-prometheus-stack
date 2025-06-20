#!/bin/bash

# =============================================================================
# PROMETHEUS STACK ADD-ON - RESOURCE MONITORING SCRIPT
# =============================================================================
# PURPOSE: Monitor resource usage and performance of the add-on
# USAGE:   ./monitor.sh [continuous]
# 
# This script provides:
# 1. Real-time container resource usage (CPU, Memory, Network)
# 2. Disk usage for persistent data
# 3. Service response times
# 4. Container process information
# 5. Continuous monitoring mode
#
# MONITORING METRICS:
# - Container CPU and Memory usage
# - Disk space usage for /data directory
# - Service response times (Prometheus, Alertmanager, Karma)
# - Number of running processes
# - Network connections
#
# MODES:
# - Single snapshot: ./monitor.sh
# - Continuous monitoring: ./monitor.sh continuous
#
# REQUIREMENTS: Container must be running (use build-test.sh first)
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

# Function to get container stats
get_container_stats() {
    echo "📊 Container Resource Usage"
    echo "============================"
    
    if docker ps | grep -q prometheus-stack; then
        print_status "INFO" "Container is running"
        
        # Get container stats (single snapshot)
        echo ""
        echo "🔍 Current Resource Usage:"
        docker stats --no-stream prometheus-stack-test 2>/dev/null || docker stats --no-stream prometheus-stack-dev 2>/dev/null || {
            print_status "ERROR" "Could not get container stats"
            return 1
        }
    else
        print_status "ERROR" "Container is not running"
        return 1
    fi
}

# Function to check disk usage
check_disk_usage() {
    echo ""
    echo "💾 Disk Usage Analysis"
    echo "======================"
    
    # Check host disk usage
    echo "📁 Host Disk Usage:"
    df -h . | grep -E "(Filesystem|$(pwd))"
    
    # Check container disk usage
    echo ""
    echo "📦 Container Disk Usage:"
    if docker exec prometheus-stack-test df -h /data 2>/dev/null || docker exec prometheus-stack-dev df -h /data 2>/dev/null; then
        print_status "OK" "Container disk usage retrieved"
    else
        print_status "WARN" "Could not get container disk usage"
    fi
    
    # Check specific directories
    echo ""
    echo "📂 Data Directory Sizes:"
    if docker exec prometheus-stack-test ls -lah /data/ 2>/dev/null || docker exec prometheus-stack-dev ls -lah /data/ 2>/dev/null; then
        print_status "OK" "Data directory listing retrieved"
    else
        print_status "WARN" "Could not list data directories"
    fi
}

# Function to check service response times
check_service_performance() {
    echo ""
    echo "⚡ Service Performance"
    echo "======================"
    
    local services=(
        "Prometheus:http://localhost:9090/-/healthy"
        "Alertmanager:http://localhost:9093/-/healthy"
        "Karma:http://localhost:8080/"
    )
    
    for service in "${services[@]}"; do
        local name=$(echo "$service" | cut -d: -f1)
        local url=$(echo "$service" | cut -d: -f2-)
        
        echo -n "🔍 $name response time: "
        
        # Measure response time
        local start_time=$(date +%s%N)
        if curl -f -s --max-time 10 "$url" > /dev/null 2>&1; then
            local end_time=$(date +%s%N)
            local duration=$(( (end_time - start_time) / 1000000 ))  # Convert to milliseconds
            
            if [ $duration -lt 100 ]; then
                print_status "OK" "${duration}ms"
            elif [ $duration -lt 500 ]; then
                print_status "WARN" "${duration}ms (slow)"
            else
                print_status "ERROR" "${duration}ms (very slow)"
            fi
        else
            print_status "ERROR" "unreachable"
        fi
    done
}

# Function to check process information
check_processes() {
    echo ""
    echo "🔄 Process Information"
    echo "======================"
    
    echo "📋 Running Processes:"
    if docker exec prometheus-stack-test ps aux 2>/dev/null || docker exec prometheus-stack-dev ps aux 2>/dev/null; then
        print_status "OK" "Process list retrieved"
    else
        print_status "WARN" "Could not get process list"
    fi
    
    echo ""
    echo "🔗 Network Connections:"
    if docker exec prometheus-stack-test netstat -tuln 2>/dev/null || docker exec prometheus-stack-dev netstat -tuln 2>/dev/null; then
        print_status "OK" "Network connections retrieved"
    else
        print_status "WARN" "Could not get network connections"
    fi
}

# Function to check log information
check_logs() {
    echo ""
    echo "📝 Recent Log Activity"
    echo "======================"
    
    echo "🔄 Last 10 log entries:"
    if docker logs --tail 10 prometheus-stack-test 2>/dev/null || docker logs --tail 10 prometheus-stack-dev 2>/dev/null; then
        print_status "OK" "Recent logs retrieved"
    else
        print_status "WARN" "Could not get recent logs"
    fi
}

# Function for continuous monitoring
continuous_monitoring() {
    echo "🔄 Starting Continuous Monitoring (Press Ctrl+C to stop)"
    echo "========================================================"
    
    while true; do
        clear
        echo "🕐 $(date)"
        echo "========================================================"
        
        get_container_stats
        check_disk_usage
        check_service_performance
        
        echo ""
        echo "⏳ Next update in 30 seconds..."
        sleep 30
    done
}

# Main script logic
main() {
    echo "📈 Resource Monitoring for Prometheus Stack Add-on"
    echo "=================================================="
    
    # Check if continuous mode is requested
    if [ "$1" = "continuous" ]; then
        continuous_monitoring
        exit 0
    fi
    
    # Single snapshot monitoring
    get_container_stats
    check_disk_usage
    check_service_performance
    check_processes
    check_logs
    
    echo ""
    echo "📊 Monitoring Summary"
    echo "====================="
    print_status "INFO" "Single snapshot monitoring completed"
    echo ""
    echo "💡 Usage:"
    echo "   Single snapshot: ./monitor.sh"
    echo "   Continuous mode: ./monitor.sh continuous"
    echo ""
    echo "🔧 Performance Tips:"
    echo "   - Monitor memory usage for potential leaks"
    echo "   - Check disk usage for data growth"
    echo "   - Watch response times for performance issues"
    echo "   - Review logs for errors or warnings"
}

# Run main function
main "$@" 