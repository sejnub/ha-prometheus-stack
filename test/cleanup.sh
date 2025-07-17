#!/bin/bash

# =============================================================================
# INFLUXDB STACK ADD-ON - CLEANUP SCRIPT
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
# - Test containers (influxdb-stack-test, influxdb-stack-dev)
# - Test images (influxdb-stack-test)
# - Test data directories (test-data/)
# - Docker networks (if created)
# - Docker volumes (if created)
#
# OPTIONS:
# --all:    Clean up everything including images and networks
# --force:  Force stop containers (use with caution)
#
# SAFETY FEATURES:
# - Waits for containers to fully stop before cleanup
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

# Configuration
CONTAINER_NAMES=("influxdb-stack-test" "influxdb-stack-dev")
IMAGE_NAMES=("influxdb-stack-test" "influxdb-stack-dev")
NETWORK_NAME="influxdb-dev-network"
TEST_DATA_DIR="$PROJECT_ROOT/test-data"

# Parse command line arguments
CLEAN_ALL=false
FORCE_CLEANUP=false

for arg in "$@"; do
    case $arg in
        --all)
            CLEAN_ALL=true
            shift
            ;;
        --force)
            FORCE_CLEANUP=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--all] [--force]"
            echo ""
            echo "Options:"
            echo "  --all    Clean up everything including images and networks"
            echo "  --force  Force stop containers (use with caution)"
            echo ""
            echo "Examples:"
            echo "  $0                 # Basic cleanup (containers and data)"
            echo "  $0 --all           # Full cleanup (containers, images, networks, data)"
            echo "  $0 --force         # Force cleanup stuck containers"
            echo "  $0 --all --force   # Force full cleanup"
            exit 0
            ;;
        *)
            print_status "ERROR" "Unknown argument: $arg"
            exit 1
            ;;
    esac
done

# Function to check if Docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        print_status "ERROR" "Docker is not running or not accessible"
        exit 1
    fi
}

# Function to stop containers
stop_containers() {
    print_status "INFO" "Stopping test containers..."
    
    local stopped_count=0
    
    for container in "${CONTAINER_NAMES[@]}"; do
        if docker ps -q --filter "name=$container" | grep -q .; then
            print_status "INFO" "Stopping container: $container"
            
            if [ "$FORCE_CLEANUP" = true ]; then
                docker kill "$container" >/dev/null 2>&1 || true
                print_status "WARN" "Force killed container: $container"
            else
                docker stop "$container" >/dev/null 2>&1 || true
                print_status "OK" "Stopped container: $container"
            fi
            
            stopped_count=$((stopped_count + 1))
        fi
    done
    
    if [ $stopped_count -eq 0 ]; then
        print_status "INFO" "No running containers to stop"
    else
        print_status "OK" "Stopped $stopped_count container(s)"
    fi
}

# Function to remove containers
remove_containers() {
    print_status "INFO" "Removing test containers..."
    
    local removed_count=0
    
    for container in "${CONTAINER_NAMES[@]}"; do
        if docker ps -aq --filter "name=$container" | grep -q .; then
            print_status "INFO" "Removing container: $container"
            docker rm "$container" >/dev/null 2>&1 || true
            removed_count=$((removed_count + 1))
        fi
    done
    
    if [ $removed_count -eq 0 ]; then
        print_status "INFO" "No containers to remove"
    else
        print_status "OK" "Removed $removed_count container(s)"
    fi
}

# Function to remove images
remove_images() {
    if [ "$CLEAN_ALL" = false ]; then
        print_status "INFO" "Skipping image cleanup (use --all to clean images)"
        return
    fi
    
    print_status "INFO" "Removing test images..."
    
    local removed_count=0
    
    for image in "${IMAGE_NAMES[@]}"; do
        if docker images -q "$image" | grep -q .; then
            print_status "INFO" "Removing image: $image"
            docker rmi "$image" >/dev/null 2>&1 || true
            removed_count=$((removed_count + 1))
        fi
    done
    
    if [ $removed_count -eq 0 ]; then
        print_status "INFO" "No images to remove"
    else
        print_status "OK" "Removed $removed_count image(s)"
    fi
}

# Function to remove networks
remove_networks() {
    if [ "$CLEAN_ALL" = false ]; then
        print_status "INFO" "Skipping network cleanup (use --all to clean networks)"
        return
    fi
    
    print_status "INFO" "Removing test networks..."
    
    if docker network ls --filter "name=$NETWORK_NAME" | grep -q "$NETWORK_NAME"; then
        print_status "INFO" "Removing network: $NETWORK_NAME"
        docker network rm "$NETWORK_NAME" >/dev/null 2>&1 || true
        print_status "OK" "Removed network: $NETWORK_NAME"
    else
        print_status "INFO" "No networks to remove"
    fi
}

# Function to clean up test data
cleanup_test_data() {
    print_status "INFO" "Cleaning up test data..."
    
    if [ -d "$TEST_DATA_DIR" ]; then
        # Get size before cleanup
        local size_before=$(du -sh "$TEST_DATA_DIR" 2>/dev/null | cut -f1 || echo "0B")
        
        # Remove contents but keep directory
        rm -rf "$TEST_DATA_DIR"/*
        rm -rf "$TEST_DATA_DIR"/.*  2>/dev/null || true
        
        print_status "OK" "Cleaned up test data directory ($size_before freed)"
    else
        print_status "INFO" "Test data directory does not exist"
    fi
}

# Function to clean up Docker system
cleanup_docker_system() {
    if [ "$CLEAN_ALL" = false ]; then
        print_status "INFO" "Skipping Docker system cleanup (use --all for system cleanup)"
        return
    fi
    
    print_status "INFO" "Cleaning up Docker system..."
    
    # Remove unused volumes
    local volumes_removed=$(docker volume prune -f 2>/dev/null | grep "Total reclaimed space" || echo "0B")
    if [ "$volumes_removed" != "0B" ]; then
        print_status "OK" "Removed unused volumes: $volumes_removed"
    fi
    
    # Remove unused networks
    docker network prune -f >/dev/null 2>&1 || true
    print_status "OK" "Removed unused networks"
}

# Function to verify cleanup
verify_cleanup() {
    print_status "INFO" "Verifying cleanup..."
    
    local issues=0
    
    # Check for remaining containers
    for container in "${CONTAINER_NAMES[@]}"; do
        if docker ps -aq --filter "name=$container" | grep -q .; then
            print_status "WARN" "Container still exists: $container"
            issues=$((issues + 1))
        fi
    done
    
    # Check for remaining images (only if --all was used)
    if [ "$CLEAN_ALL" = true ]; then
        for image in "${IMAGE_NAMES[@]}"; do
            if docker images -q "$image" | grep -q .; then
                print_status "WARN" "Image still exists: $image"
                issues=$((issues + 1))
            fi
        done
    fi
    
    if [ $issues -eq 0 ]; then
        print_status "OK" "Cleanup verification passed"
    else
        print_status "WARN" "Cleanup verification found $issues issue(s)"
    fi
    
    return $issues
}

# Function to show cleanup summary
show_summary() {
    local success=$1
    
    echo ""
    echo "=========================================="
    if [ "$success" = true ]; then
        print_status "OK" "🎉 Cleanup completed successfully!"
        echo ""
        print_status "INFO" "Summary:"
        echo "  • Containers: Stopped and removed"
        echo "  • Test data: Cleaned up"
        if [ "$CLEAN_ALL" = true ]; then
            echo "  • Images: Removed"
            echo "  • Networks: Cleaned up"
            echo "  • Docker system: Pruned"
        fi
        echo ""
        print_status "INFO" "You can now run './test/build.sh' to start fresh"
    else
        print_status "ERROR" "❌ Cleanup completed with issues"
        echo ""
        print_status "INFO" "Some items may not have been cleaned up properly"
        print_status "INFO" "You may need to manually clean up remaining items"
    fi
    echo "=========================================="
    echo ""
}

# Main execution
main() {
    echo ""
    echo "🧹 InfluxDB Stack Add-on - Cleanup Script"
    echo "========================================="
    echo "Project root: $PROJECT_ROOT"
    echo "Test data dir: $TEST_DATA_DIR"
    
    if [ "$CLEAN_ALL" = true ]; then
        echo "Mode: Full cleanup (containers, images, networks, data)"
    else
        echo "Mode: Basic cleanup (containers and data only)"
    fi
    
    if [ "$FORCE_CLEANUP" = true ]; then
        echo "Force mode: Enabled"
    fi
    
    echo ""
    
    # Check prerequisites
    check_docker
    
    # Perform cleanup steps
    stop_containers
    remove_containers
    remove_images
    remove_networks
    cleanup_test_data
    cleanup_docker_system
    
    # Verify cleanup
    if verify_cleanup; then
        show_summary true
        exit 0
    else
        show_summary false
        exit 1
    fi
}

# Error handler
handle_error() {
    print_status "ERROR" "An unexpected error occurred during cleanup"
    exit 1
}

# Set up error handling
trap handle_error ERR

# Run main function
main "$@" 