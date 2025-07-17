#!/bin/bash

# =============================================================================
# INFLUXDB STACK ADD-ON - RESOURCE MONITORING SCRIPT
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
# - Service response times (InfluxDB, Grafana, VS Code)
# - Number of running processes
# - Network connections
#
# MODES:
# - Single snapshot: ./monitor.sh
# - Continuous monitoring: ./monitor.sh continuous
#
# REQUIREMENTS: Container must be running (use build.sh first)
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

# Container name
CONTAINER_NAME="influxdb-stack-test"

# Function to check if container is running
check_container() {
    if ! docker ps --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
        print_status "ERROR" "Container '$CONTAINER_NAME' is not running"
        print_status "INFO" "Please run './test/build.sh' first"
        exit 1
    fi
}

# Function to get container stats
get_container_stats() {
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}" "$CONTAINER_NAME"
}

# Function to get disk usage
get_disk_usage() {
    echo ""
    print_status "INFO" "📁 Disk Usage:"
    echo "----------------------------------------"
    
    # Host disk usage for test-data directory
    if [ -d "./test-data" ]; then
        local host_usage=$(du -sh ./test-data 2>/dev/null || echo "0B")
        echo "Host test-data directory: $host_usage"
    fi
    
    # Container disk usage
    echo "Container disk usage:"
    docker exec "$CONTAINER_NAME" df -h /data 2>/dev/null || echo "  /data: Not available"
    
    # InfluxDB data directory
    local influxdb_size=$(docker exec "$CONTAINER_NAME" du -sh /data/influxdb 2>/dev/null || echo "0B")
    echo "InfluxDB data: $influxdb_size"
    
    # Grafana data directory
    local grafana_size=$(docker exec "$CONTAINER_NAME" du -sh /data/grafana 2>/dev/null || echo "0B")
    echo "Grafana data: $grafana_size"
}

# Function to get service response times
get_service_response_times() {
    echo ""
    print_status "INFO" "⏱️  Service Response Times:"
    echo "----------------------------------------"
    
    # InfluxDB health check
    local influxdb_time=$(curl -o /dev/null -s -w "%{time_total}" "http://localhost:8086/health" 2>/dev/null || echo "N/A")
    if [ "$influxdb_time" != "N/A" ]; then
        printf "InfluxDB health:     %.3f seconds\n" "$influxdb_time"
    else
        echo "InfluxDB health:     Not responding"
    fi
    
    # Grafana health check
    local grafana_time=$(curl -o /dev/null -s -w "%{time_total}" "http://localhost:3000/api/health" 2>/dev/null || echo "N/A")
    if [ "$grafana_time" != "N/A" ]; then
        printf "Grafana health:      %.3f seconds\n" "$grafana_time"
    else
        echo "Grafana health:      Not responding"
    fi
    
    # VS Code check
    local vscode_time=$(curl -o /dev/null -s -w "%{time_total}" "http://localhost:8443/" 2>/dev/null || echo "N/A")
    if [ "$vscode_time" != "N/A" ]; then
        printf "VS Code:             %.3f seconds\n" "$vscode_time"
    else
        echo "VS Code:             Not responding"
    fi
    
    # NGINX status
    local nginx_time=$(curl -o /dev/null -s -w "%{time_total}" "http://localhost:80/nginx_status" 2>/dev/null || echo "N/A")
    if [ "$nginx_time" != "N/A" ]; then
        printf "NGINX status:        %.3f seconds\n" "$nginx_time"
    else
        echo "NGINX status:        Not responding"
    fi
}

# Function to get process information
get_process_info() {
    echo ""
    print_status "INFO" "🔄 Process Information:"
    echo "----------------------------------------"
    
    # Get process count
    local process_count=$(docker exec "$CONTAINER_NAME" ps aux | wc -l)
    echo "Total processes: $((process_count - 1))"
    
    # Get key processes
    echo ""
    echo "Key processes:"
    docker exec "$CONTAINER_NAME" ps aux | grep -E "(influxd|grafana|code-server|nginx)" | grep -v grep | while read line; do
        echo "  $line"
    done
}

# Function to get network information
get_network_info() {
    echo ""
    print_status "INFO" "🌐 Network Information:"
    echo "----------------------------------------"
    
    # Get listening ports
    echo "Listening ports:"
    docker exec "$CONTAINER_NAME" netstat -tlnp 2>/dev/null | grep LISTEN | while read line; do
        echo "  $line"
    done
    
    # Get network connections
    echo ""
    echo "Active connections:"
    local connection_count=$(docker exec "$CONTAINER_NAME" netstat -tn 2>/dev/null | grep ESTABLISHED | wc -l)
    echo "  Established connections: $connection_count"
}

# Function to get service status
get_service_status() {
    echo ""
    print_status "INFO" "🏥 Service Health Status:"
    echo "----------------------------------------"
    
    # InfluxDB status
    if curl -s "http://localhost:8086/health" | grep -q '"status":"pass"'; then
        echo "InfluxDB:            ✅ Healthy"
    else
        echo "InfluxDB:            ❌ Unhealthy"
    fi
    
    # Grafana status
    if curl -s "http://localhost:3000/api/health" | grep -q '"database":"ok"'; then
        echo "Grafana:             ✅ Healthy"
    else
        echo "Grafana:             ❌ Unhealthy"
    fi
    
    # VS Code status
    if curl -s "http://localhost:8443/" | grep -q -i "vs code\|code-server"; then
        echo "VS Code:             ✅ Healthy"
    else
        echo "VS Code:             ❌ Unhealthy"
    fi
    
    # NGINX status
    if curl -s "http://localhost:80/nginx_status" | grep -q "Active connections"; then
        echo "NGINX:               ✅ Healthy"
    else
        echo "NGINX:               ❌ Unhealthy"
    fi
}

# Function to display monitoring header
show_header() {
    echo ""
    echo "📊 InfluxDB Stack Add-on - Resource Monitor"
    echo "==========================================="
    echo "Container: $CONTAINER_NAME"
    echo "Timestamp: $(date)"
    echo ""
}

# Function to display all monitoring information
show_monitoring_info() {
    show_header
    
    # Container resource stats
    print_status "INFO" "🐳 Container Resource Usage:"
    echo "----------------------------------------"
    get_container_stats
    
    # Disk usage
    get_disk_usage
    
    # Service response times
    get_service_response_times
    
    # Service health status
    get_service_status
    
    # Process information
    get_process_info
    
    # Network information
    get_network_info
    
    echo ""
    echo "=========================================="
}

# Function for continuous monitoring
continuous_monitor() {
    print_status "INFO" "Starting continuous monitoring (Press Ctrl+C to stop)..."
    echo ""
    
    while true; do
        clear
        show_monitoring_info
        echo ""
        print_status "INFO" "Refreshing in 5 seconds..."
        sleep 5
    done
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [continuous]"
    echo ""
    echo "Options:"
    echo "  (no args)    Show single monitoring snapshot"
    echo "  continuous   Start continuous monitoring (refresh every 5 seconds)"
    echo ""
    echo "Examples:"
    echo "  $0                 # Single snapshot"
    echo "  $0 continuous      # Continuous monitoring"
}

# Main execution
main() {
    local mode="${1:-single}"
    
    # Check if container is running
    check_container
    
    case "$mode" in
        "continuous")
            continuous_monitor
            ;;
        "single"|"")
            show_monitoring_info
            ;;
        "help"|"-h"|"--help")
            show_usage
            ;;
        *)
            print_status "ERROR" "Unknown mode: $mode"
            show_usage
            exit 1
            ;;
    esac
}

# Error handler
handle_error() {
    print_status "ERROR" "An error occurred during monitoring"
    exit 1
}

# Set up error handling
trap handle_error ERR

# Handle Ctrl+C gracefully in continuous mode
trap 'echo ""; print_status "INFO" "Monitoring stopped by user"; exit 0' INT

# Run main function
main "$@" 