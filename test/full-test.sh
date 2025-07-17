#!/bin/bash

# =============================================================================
# INFLUXDB STACK ADD-ON - FULL TEST SCRIPT
# =============================================================================
# PURPOSE: Run complete test cycle: cleanup → build → health check
# USAGE:   ./test/full-test.sh
# 
# This script runs the following tests in sequence:
# 1. cleanup.sh - Clean up any existing test containers and data
# 2. build.sh - Build and start the add-on container
# 3. health-check.sh - Verify all services are healthy
#
# The script will stop at the first failure and report the status.
# =============================================================================

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored status messages
print_status() {
    local status=$1
    local message=$2
    case $status in
        "INFO")
            echo -e "${BLUE}[INFO]${NC} $message"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[SUCCESS]${NC} $message"
            ;;
        "WARNING")
            echo -e "${YELLOW}[WARNING]${NC} $message"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $message"
            ;;
        *)
            echo "[$status] $message"
            ;;
    esac
}

# Function to run a script and handle errors
run_script() {
    local script_name=$1
    local script_path=$2
    local description=$3
    
    print_status "INFO" "Starting $description..."
    
    if [ -f "$script_path" ]; then
        if bash "$script_path"; then
            print_status "SUCCESS" "$description completed successfully"
            return 0
        else
            print_status "ERROR" "$description failed"
            return 1
        fi
    else
        print_status "ERROR" "Script not found: $script_path"
        return 1
    fi
}

# Function to show script header
show_header() {
    echo ""
    echo ""
    echo ""
    echo "🧪 InfluxDB Stack Add-on - Full Test Cycle"
    echo "=========================================="
    echo "This script will run the complete test cycle:"
    echo "  1. 🧹 Cleanup existing test environment"
    echo "  2. 🔨 Build and start InfluxDB Stack container"
    echo "  3. 🏥 Health check all services"
    echo ""
}

# Function to show final results
show_results() {
    local success=$1
    echo ""
    echo "=========================================="
    if [ "$success" = "true" ]; then
        print_status "SUCCESS" "🎉 All tests passed! InfluxDB Stack is ready for use."
        echo ""
        echo "📊 Access your InfluxDB Stack:"
        echo "  • InfluxDB UI:    http://localhost:8086"
        echo "  • Grafana:        http://localhost:3000"
        echo "  • VS Code:        http://localhost:8443"
        echo "  • Main Interface: http://localhost:80"
        echo ""
        echo "🔧 Useful commands:"
        echo "  • View logs:      docker logs influxdb-stack-test"
        echo "  • Stop container: docker stop influxdb-stack-test"
        echo "  • Clean up:       ./test/cleanup.sh"
    else
        print_status "ERROR" "❌ Test cycle failed. Check the logs above for details."
        echo ""
        echo "🔧 Troubleshooting:"
        echo "  • Check Docker is running: docker info"
        echo "  • View container logs: docker logs influxdb-stack-test"
        echo "  • Clean up and retry: ./test/cleanup.sh && ./test/full-test.sh"
    fi
    echo "=========================================="
    echo ""
}

# Main execution
main() {
    show_header
    
    # Get script directory
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Define test scripts
    local cleanup_script="$script_dir/cleanup.sh"
    local build_script="$script_dir/build.sh"
    local health_script="$script_dir/health-check.sh"
    
    # Step 1: Cleanup
    if ! run_script "cleanup.sh" "$cleanup_script" "Environment cleanup"; then
        show_results "false"
        exit 1
    fi
    
    echo ""
    
    # Step 2: Build
    if ! run_script "build.sh" "$build_script" "Container build and startup"; then
        show_results "false"
        exit 1
    fi
    
    echo ""
    
    # Step 3: Health check
    if ! run_script "health-check.sh" "$health_script" "Service health verification"; then
        show_results "false"
        exit 1
    fi
    
    # All tests passed
    show_results "true"
    exit 0
}

# Error handler
handle_error() {
    print_status "ERROR" "An unexpected error occurred during testing"
    show_results "false"
    exit 1
}

# Set up error handling
trap handle_error ERR

# Run main function
main "$@" 