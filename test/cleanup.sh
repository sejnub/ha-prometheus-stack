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

# Function to check if Docker is running
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_status "ERROR" "Docker is not installed"
        return 1
    fi
    
    if ! docker info &> /dev/null; then
        print_status "ERROR" "Docker is not running"
        return 1
    fi
    
    print_status "OK" "Docker is available and running"
    return 0
}

# Function to wait for container to stop
wait_for_container_stop() {
    local container="$1"
    local max_attempts=120  # Maximum number of attempts (120 * 0.5 seconds = 60 seconds timeout)
    local attempts=0
    
    while docker ps -q --filter "name=$container" | grep -q . && [ $attempts -lt $max_attempts ]; do
        print_status "INFO" "Waiting for container $container to stop... ($(( (max_attempts - attempts) / 2 )) seconds remaining)"
        sleep 0.5
        attempts=$((attempts + 1))
    done
    
    if [ $attempts -eq $max_attempts ]; then
        print_status "ERROR" "Timeout waiting for container $container to stop"
        return 1
    fi
    
    return 0
}

# Function to stop and remove containers
cleanup_containers() {
    echo ""
    echo "🐳 Container Cleanup"
    echo "===================="
    
    local containers=("prometheus-stack-test" "prometheus-stack-dev")
    local containers_found=0
    local all_containers_stopped=0  # 0 means success in bash
    
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
                
                # Wait for container to stop
                if ! wait_for_container_stop "$container"; then
                    all_containers_stopped=1  # 1 means failure in bash
                    continue
                fi
            fi
            
            # Remove container
            print_status "INFO" "Removing container $container"
            if ! docker rm "$container" 2>/dev/null; then
                print_status "WARN" "Could not remove container $container"
                all_containers_stopped=1  # 1 means failure in bash
            else
                print_status "OK" "Container $container removed"
            fi
        fi
    done
    
    if [ $containers_found -eq 0 ]; then
        print_status "INFO" "No test containers found"
    fi
    
    return $all_containers_stopped
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
        echo "ℹ️  Found test-data directory"
        echo "📋 Contents to be removed:"
        ls -la "$PROJECT_ROOT/test-data"
        
        # Use Docker to remove the entire test-data directory
        docker run --rm -v "$PROJECT_ROOT:/workspace" alpine:latest rm -rf /workspace/test-data
        
        print_status "OK" "Test data directory cleaned"
        return 0
    else
        print_status "INFO" "No test-data directory found"
        return 0
    fi
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
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Main cleanup sequence
main() {
    echo ""
    echo ""
    echo ""
    echo "🧹  Running Cleanup for Prometheus Stack Add-on"
    echo "================================================"
    echo "📁 Project root: $PROJECT_ROOT"
    echo "📁 Test directory: $TEST_DIR"
    
    # Check Docker availability
    if ! check_docker; then
        echo ""
        print_status "ERROR" "❌ Cleanup failed: Docker not available ❌"
        exit 1
    fi
    
    # Show cleanup mode
    if [ "$CLEAN_ALL" = "true" ]; then
        print_status "INFO" "Full cleanup mode enabled"
    else
        print_status "INFO" "Basic cleanup mode (use --all for full cleanup)"
    fi
    
    if [ "$FORCE" = "true" ]; then
        print_status "WARN" "Force mode enabled - containers will be killed"
    fi
    
    # Stop and remove containers first
    if cleanup_containers; then
        # Only proceed with other cleanups if containers are properly stopped
        cleanup_images
        cleanup_networks
        cleanup_volumes
        cleanup_test_data
        
        # Show summary
        echo ""
        echo "📊 Cleanup Summary"
        echo "=================="
        
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
        print_status "OK" "✨ Cleanup completed successfully ✨"
        exit 0
    else
        echo ""
        print_status "ERROR" "❌ Cleanup failed: Could not stop/remove containers ❌"
        exit 1
    fi
}

# Run main function
main 