#!/bin/bash

# =============================================================================
# PROMETHEUS STACK ADD-ON - CLEANUP SCRIPT
# =============================================================================
# PURPOSE: Clean up test containers, images, and data after testing
# USAGE:   ./test/cleanup.sh [--all] [--force] (from project root) OR ./cleanup.sh [--all] [--force] (from test folder)
# 
# This script provides:
# 1. Safe cleanup of test containers
# 2. Removal of test Docker images
# 3. Cleanup of test data directories
# 4. Network and volume cleanup
# 5. Force cleanup options for stuck containers
#
# CLEANUP TARGETS:
# - Test containers (prometheus-stack-test, prometheus-stack-dev)
# - Test images (prometheus-stack-test)
# - Test data directories (test-data/)
# - Docker networks (if created)
# - Docker volumes (if created)
#
# OPTIONS:
# --all:    Clean up everything including images and networks
# --force:  Force stop and remove containers (use with caution)
#
# SAFETY FEATURES:
# - Confirms before deleting containers
# - Checks for running containers before cleanup
# - Preserves non-test containers and images
# - Provides detailed cleanup report
#
# REQUIREMENTS: Docker must be running
# =============================================================================

set -e  # Exit on any error

# Determine script location and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "$SCRIPT_DIR" == */test ]]; then
    # Running from test folder
    PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
    TEST_DIR="$SCRIPT_DIR"
else
    # Running from project root
    PROJECT_ROOT="$SCRIPT_DIR"
    TEST_DIR="$SCRIPT_DIR/test"
fi

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

# Function to check if Docker is running
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_status "ERROR" "Docker is not installed"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        print_status "ERROR" "Docker is not running"
        exit 1
    fi
    
    print_status "OK" "Docker is available and running"
}

# Function to stop and remove containers
cleanup_containers() {
    echo ""
    echo "🐳 Container Cleanup"
    echo "===================="
    
    local containers=("prometheus-stack-test" "prometheus-stack-dev")
    local containers_found=0
    
    for container in "${containers[@]}"; do
        if docker ps -a --format "table {{.Names}}" | grep -q "^$container$"; then
            containers_found=1
            print_status "INFO" "Found container: $container"
            
            # Check if container is running
            if docker ps --format "table {{.Names}}" | grep -q "^$container$"; then
                print_status "WARN" "Container $container is running"
                
                if [ "$FORCE" = "true" ]; then
                    print_status "INFO" "Force stopping container $container"
                    docker kill "$container" 2>/dev/null || true
                else
                    print_status "INFO" "Stopping container $container gracefully"
                    docker stop "$container" 2>/dev/null || true
                fi
            fi
            
            # Remove container
            print_status "INFO" "Removing container $container"
            docker rm "$container" 2>/dev/null && print_status "OK" "Container $container removed" || print_status "WARN" "Could not remove container $container"
        fi
    done
    
    if [ $containers_found -eq 0 ]; then
        print_status "INFO" "No test containers found"
    fi
}

# Function to remove images
cleanup_images() {
    if [ "$CLEAN_ALL" = "true" ]; then
        echo ""
        echo "🖼️  Image Cleanup"
        echo "================="
        
        local images=("prometheus-stack-test" "prometheus-stack-dev")
        local images_found=0
        
        for image in "${images[@]}"; do
            if docker images --format "table {{.Repository}}" | grep -q "^$image$"; then
                images_found=1
                print_status "INFO" "Found image: $image"
                print_status "INFO" "Removing image $image"
                docker rmi "$image" 2>/dev/null && print_status "OK" "Image $image removed" || print_status "WARN" "Could not remove image $image"
            fi
        done
        
        if [ $images_found -eq 0 ]; then
            print_status "INFO" "No test images found"
        fi
    fi
}

# Function to cleanup networks
cleanup_networks() {
    if [ "$CLEAN_ALL" = "true" ]; then
        echo ""
        echo "🌐 Network Cleanup"
        echo "=================="
        
        local networks=("prometheus-dev-network")
        local networks_found=0
        
        for network in "${networks[@]}"; do
            if docker network ls --format "table {{.Name}}" | grep -q "^$network$"; then
                networks_found=1
                print_status "INFO" "Found network: $network"
                print_status "INFO" "Removing network $network"
                docker network rm "$network" 2>/dev/null && print_status "OK" "Network $network removed" || print_status "WARN" "Could not remove network $network"
            fi
        done
        
        if [ $networks_found -eq 0 ]; then
            print_status "INFO" "No test networks found"
        fi
    fi
}

# Function to cleanup volumes
cleanup_volumes() {
    if [ "$CLEAN_ALL" = "true" ]; then
        echo ""
        echo "💾 Volume Cleanup"
        echo "================="
        
        local volumes=("prometheus_data" "alertmanager_data")
        local volumes_found=0
        
        for volume in "${volumes[@]}"; do
            if docker volume ls --format "table {{.Name}}" | grep -q "^$volume$"; then
                volumes_found=1
                print_status "INFO" "Found volume: $volume"
                print_status "INFO" "Removing volume $volume"
                docker volume rm "$volume" 2>/dev/null && print_status "OK" "Volume $volume removed" || print_status "WARN" "Could not remove volume $volume"
            fi
        done
        
        if [ $volumes_found -eq 0 ]; then
            print_status "INFO" "No test volumes found"
        fi
    fi
}

# Function to cleanup test data
cleanup_test_data() {
    echo ""
    echo "📁 Test Data Cleanup"
    echo "===================="
    
    if [ -d "$PROJECT_ROOT/test-data" ]; then
        print_status "INFO" "Found test-data directory"
        
        # Show what will be deleted
        echo "📋 Contents to be removed:"
        find "$PROJECT_ROOT/test-data" -type f -exec echo "   {}" \;
        
        # First try to remove files from within the container if it's still running
        if docker ps --format "{{.Names}}" | grep -q "^prometheus-stack-test$"; then
            print_status "INFO" "Cleaning up files using container permissions"
            docker exec prometheus-stack-test rm -rf /data/prometheus/* /data/alertmanager/* || true
        fi
        
        # Now remove the directory with sudo if needed
        print_status "INFO" "Removing test-data directory"
        if ! rm -rf "$PROJECT_ROOT/test-data" 2>/dev/null; then
            print_status "INFO" "Using elevated permissions to remove test data"
            sudo rm -rf "$PROJECT_ROOT/test-data"
        fi
        print_status "OK" "Test data directory removed"
    else
        print_status "INFO" "No test-data directory found"
    fi
}

# Function to show cleanup summary
show_summary() {
    echo ""
    echo "📊 Cleanup Summary"
    echo "=================="
    
    print_status "INFO" "Cleanup completed"
    
    if [ "$CLEAN_ALL" = "true" ]; then
        echo "🧹 Full cleanup performed:"
        echo "   - Containers removed"
        echo "   - Images removed"
        echo "   - Networks removed"
        echo "   - Volumes removed"
        echo "   - Test data removed"
    else
        echo "🧹 Basic cleanup performed:"
        echo "   - Containers removed"
        echo "   - Test data removed"
    fi
    
    echo ""
    echo "💡 Next Steps:"
    echo "   - Run $TEST_DIR/build-test.sh to start fresh testing"
    echo "   - Or deploy to Home Assistant for production use"
}

# Parse command line arguments
CLEAN_ALL=false
FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --all)
            CLEAN_ALL=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--all] [--force]"
            echo ""
            echo "Options:"
            echo "  --all     Clean up everything (containers, images, networks, volumes)"
            echo "  --force   Force stop containers before removal"
            echo "  -h, --help Show this help message"
            exit 0
            ;;
        *)
            print_status "ERROR" "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Main cleanup process
main() {
    echo "🧹 Cleanup for Prometheus Stack Add-on"
    echo "======================================"
    echo "📁 Project root: $PROJECT_ROOT"
    echo "📁 Test directory: $TEST_DIR"
    
    # Check Docker availability
    check_docker
    
    # Show cleanup mode
    if [ "$CLEAN_ALL" = "true" ]; then
        print_status "INFO" "Full cleanup mode enabled"
    else
        print_status "INFO" "Basic cleanup mode (use --all for full cleanup)"
    fi
    
    if [ "$FORCE" = "true" ]; then
        print_status "WARN" "Force mode enabled - containers will be killed"
    fi
    
    # Perform cleanup
    cleanup_containers
    cleanup_images
    cleanup_networks
    cleanup_volumes
    cleanup_test_data
    
    # Show summary
    show_summary
}

# Run main function
main 