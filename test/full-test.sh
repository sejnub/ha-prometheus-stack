#!/bin/bash

# =============================================================================
# PROMETHEUS STACK ADD-ON - FULL TEST SCRIPT
# =============================================================================
# PURPOSE: Run complete test cycle: cleanup → build → health check
# USAGE:   ./test/full-test.sh
# 
# This script runs the following tests in sequence:
# 1. cleanup.sh - Clean up any existing test containers and data
# 2. build-test.sh - Build and start the add-on container
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
    local script_path="$PROJECT_ROOT/test/$script_name"
    
    print_status "INFO" "Running $script_name..."
    
    if [ ! -f "$script_path" ]; then
        print_status "ERROR" "Script not found: $script_path"
        exit 1
    fi
    
    if [ ! -x "$script_path" ]; then
        print_status "INFO" "Making $script_name executable..."
        chmod +x "$script_path"
    fi
    
    # Run the script and capture output
    if "$script_path"; then
        print_status "SUCCESS" "$script_name completed successfully"
        return 0
    else
        print_status "ERROR" "$script_name failed with exit code $?"
        return 1
    fi
}

# Main execution
main() {
    echo "=============================================================================="
    echo "                    PROMETHEUS STACK - FULL TEST SUITE"
    echo "=============================================================================="
    echo
    
    # Get the project root directory
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    export PROJECT_ROOT
    
    print_status "INFO" "Project root: $PROJECT_ROOT"
    print_status "INFO" "Starting full test cycle..."
    echo
    
    # Step 1: Cleanup
    echo "--- STEP 1: CLEANUP ---"
    if ! run_script "cleanup.sh"; then
        print_status "ERROR" "❌ Full test failed during cleanup step"
        exit 1
    fi
    echo
    
    # Step 2: Build and start
    echo "--- STEP 2: BUILD AND START ---"
    if ! run_script "build-test.sh"; then
        print_status "ERROR" "❌ Full test failed during build step"
        exit 1
    fi
    echo
    
    # Step 3: Health check
    echo "--- STEP 3: HEALTH CHECK ---"
    if ! run_script "health-check.sh"; then
        print_status "ERROR" "❌ Full test failed during health check step"
        print_status "INFO" "Container logs might help diagnose the issue:"
        print_status "INFO" "  docker logs prometheus-stack-test"
        exit 1
    fi
    echo
    
    # Success message
    echo "=============================================================================="
    print_status "SUCCESS" "🎉 ALL TESTS PASSED! 🎉"
    echo "=============================================================================="
    print_status "INFO" "The Prometheus Stack add-on is running and healthy!"
    print_status "INFO" "Access the services at:"
    print_status "INFO" "  - Main UI: http://localhost:80"
    print_status "INFO" "  - Prometheus: http://localhost:9090"
    print_status "INFO" "  - Alertmanager: http://localhost:9093"
    print_status "INFO" "  - Blackbox: http://localhost:9115"
    print_status "INFO" "  - Karma: http://localhost:8080"
    echo
    print_status "INFO" "To stop the test container, run: ./test/cleanup.sh"
    echo "=============================================================================="
}

# Run main function
main "$@" 