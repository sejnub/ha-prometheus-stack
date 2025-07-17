#!/bin/bash

# =============================================================================
# INFLUXDB STACK ADD-ON - CONFIGURATION TESTING SCRIPT
# =============================================================================
# PURPOSE: Test the add-on with different configuration scenarios
# USAGE:   ./test-config.sh
# 
# This script tests:
# 1. Different InfluxDB organization and bucket configurations
# 2. Various authentication configurations
# 3. Configuration file generation
# 4. Dynamic configuration reloading
#
# TEST SCENARIOS:
# - Basic configuration validation
# - Organization and bucket validation
# - Authentication token validation
# - Configuration file syntax checking
# - Service restart with new configuration
#
# REQUIREMENTS: 
# - Container must be running (use build.sh first)
# - jq for JSON parsing (included in Dockerfile)
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

echo ""
echo ""
echo ""
echo "🧪 InfluxDB Stack Add-on - Configuration Testing"
echo "=============================================="
echo ""

# Configuration test scenarios
declare -A TEST_CONFIGS=(
    ["basic"]='{"influxdb_org":"test-org","influxdb_bucket":"test-bucket","influxdb_username":"admin","influxdb_password":"testpass123","influxdb_token":"","grafana_admin_password":"admin"}'
    ["production"]='{"influxdb_org":"production","influxdb_bucket":"metrics","influxdb_username":"influxdb_admin","influxdb_password":"SecurePass123!","influxdb_token":"my-super-secret-token","grafana_admin_password":"GrafanaSecure123"}'
    ["development"]='{"influxdb_org":"dev-team","influxdb_bucket":"development","influxdb_username":"dev","influxdb_password":"devpass","influxdb_token":"dev-token-123","grafana_admin_password":"devpass"}'
    ["special-chars"]='{"influxdb_org":"test-org-123","influxdb_bucket":"test_bucket_data","influxdb_username":"test.user","influxdb_password":"P@ssw0rd!","influxdb_token":"test-token-with-dashes","grafana_admin_password":"Test123!"}'
)

# Function to check if container is running
check_container() {
    if ! docker ps --format '{{.Names}}' | grep -q '^influxdb-stack-test$'; then
        print_status "ERROR" "Container 'influxdb-stack-test' is not running"
        print_status "INFO" "Please run './test/build.sh' first"
        exit 1
    fi
    print_status "OK" "Container is running"
}

# Function to backup current configuration
backup_config() {
    local backup_file="./test-data/options.json.backup"
    if [ -f "./test-data/options.json" ]; then
        cp "./test-data/options.json" "$backup_file"
        print_status "OK" "Current configuration backed up to $backup_file"
    fi
}

# Function to restore configuration
restore_config() {
    local backup_file="./test-data/options.json.backup"
    if [ -f "$backup_file" ]; then
        cp "$backup_file" "./test-data/options.json"
        rm "$backup_file"
        print_status "OK" "Configuration restored from backup"
    fi
}

# Function to test configuration
test_config() {
    local config_name="$1"
    local config_json="$2"
    
    print_status "INFO" "Testing configuration: $config_name"
    
    # Write test configuration
    echo "$config_json" > "./test-data/options.json"
    
    # Restart container to apply new configuration
    print_status "INFO" "Restarting container with new configuration..."
    docker restart influxdb-stack-test >/dev/null 2>&1
    
    # Wait for container to be ready
    local max_wait=30
    local wait_count=0
    
    while [ $wait_count -lt $max_wait ]; do
        if docker exec influxdb-stack-test curl -s http://localhost:8086/health >/dev/null 2>&1; then
            break
        fi
        sleep 1
        wait_count=$((wait_count + 1))
    done
    
    if [ $wait_count -eq $max_wait ]; then
        print_status "ERROR" "Container failed to start with configuration: $config_name"
        return 1
    fi
    
    # Test InfluxDB health
    if docker exec influxdb-stack-test curl -s http://localhost:8086/health | grep -q '"status":"pass"'; then
        print_status "OK" "InfluxDB health check passed"
    else
        print_status "ERROR" "InfluxDB health check failed"
        return 1
    fi
    
    # Test Grafana health
    if docker exec influxdb-stack-test curl -s http://localhost:3000/api/health | grep -q '"database":"ok"'; then
        print_status "OK" "Grafana health check passed"
    else
        print_status "ERROR" "Grafana health check failed"
        return 1
    fi
    
    # Test configuration file generation
    if docker exec influxdb-stack-test test -f /etc/grafana/provisioning/datasources/influxdb.yml; then
        print_status "OK" "InfluxDB datasource configuration generated"
    else
        print_status "ERROR" "InfluxDB datasource configuration not found"
        return 1
    fi
    
    # Test that configuration values are properly substituted
    local org_value=$(echo "$config_json" | jq -r '.influxdb_org')
    local bucket_value=$(echo "$config_json" | jq -r '.influxdb_bucket')
    
    if docker exec influxdb-stack-test grep -q "organization: $org_value" /etc/grafana/provisioning/datasources/influxdb.yml; then
        print_status "OK" "Organization value correctly substituted"
    else
        print_status "ERROR" "Organization value not properly substituted"
        return 1
    fi
    
    if docker exec influxdb-stack-test grep -q "defaultBucket: $bucket_value" /etc/grafana/provisioning/datasources/influxdb.yml; then
        print_status "OK" "Bucket value correctly substituted"
    else
        print_status "ERROR" "Bucket value not properly substituted"
        return 1
    fi
    
    print_status "OK" "Configuration test passed: $config_name"
    return 0
}

# Function to validate JSON configuration
validate_json() {
    local config_name="$1"
    local config_json="$2"
    
    if echo "$config_json" | jq . >/dev/null 2>&1; then
        print_status "OK" "JSON syntax valid for $config_name"
        return 0
    else
        print_status "ERROR" "Invalid JSON syntax for $config_name"
        return 1
    fi
}

# Function to test configuration validation
test_validation() {
    print_status "INFO" "Testing configuration validation..."
    
    # Test invalid JSON
    local invalid_json='{"influxdb_org":"test"'
    if validate_json "invalid-json" "$invalid_json"; then
        print_status "ERROR" "Invalid JSON was accepted"
        return 1
    else
        print_status "OK" "Invalid JSON properly rejected"
    fi
    
    # Test missing required fields
    local incomplete_json='{"influxdb_org":"test"}'
    if validate_json "incomplete" "$incomplete_json"; then
        print_status "OK" "Incomplete JSON syntax valid (missing fields will use defaults)"
    else
        print_status "ERROR" "Incomplete JSON rejected"
        return 1
    fi
    
    print_status "OK" "Configuration validation tests passed"
    return 0
}

# Function to test service connectivity
test_connectivity() {
    print_status "INFO" "Testing service connectivity..."
    
    # Test InfluxDB API
    if curl -s "http://localhost:8086/health" | grep -q '"status":"pass"'; then
        print_status "OK" "InfluxDB API responding"
    else
        print_status "ERROR" "InfluxDB API not responding"
        return 1
    fi
    
    # Test Grafana API
    if curl -s "http://localhost:3000/api/health" | grep -q '"database":"ok"'; then
        print_status "OK" "Grafana API responding"
    else
        print_status "ERROR" "Grafana API not responding"
        return 1
    fi
    
    # Test VS Code (if enabled)
    if curl -s "http://localhost:8443/" | grep -q -i "vs code\|code-server"; then
        print_status "OK" "VS Code responding"
    else
        print_status "WARN" "VS Code not responding (may be disabled)"
    fi
    
    # Test NGINX
    if curl -s "http://localhost:80/nginx_status" | grep -q "Active connections"; then
        print_status "OK" "NGINX responding"
    else
        print_status "ERROR" "NGINX not responding"
        return 1
    fi
    
    print_status "OK" "Service connectivity tests passed"
    return 0
}

# Main execution
main() {
    local failed_tests=0
    local total_tests=0
    
    # Check prerequisites
    check_container
    
    # Backup current configuration
    backup_config
    
    echo ""
    print_status "INFO" "Starting configuration tests..."
    echo ""
    
    # Test configuration validation
    total_tests=$((total_tests + 1))
    if ! test_validation; then
        failed_tests=$((failed_tests + 1))
    fi
    
    echo ""
    
    # Test each configuration scenario
    for config_name in "${!TEST_CONFIGS[@]}"; do
        total_tests=$((total_tests + 1))
        if ! test_config "$config_name" "${TEST_CONFIGS[$config_name]}"; then
            failed_tests=$((failed_tests + 1))
        fi
        echo ""
    done
    
    # Test service connectivity with final configuration
    total_tests=$((total_tests + 1))
    if ! test_connectivity; then
        failed_tests=$((failed_tests + 1))
    fi
    
    # Restore original configuration
    restore_config
    
    # Final results
    echo ""
    echo "=============================================="
    if [ $failed_tests -eq 0 ]; then
        print_status "OK" "🎉 All configuration tests passed! ($total_tests/$total_tests)"
        echo ""
        print_status "INFO" "Configuration testing completed successfully"
        print_status "INFO" "The InfluxDB Stack add-on handles all test configurations correctly"
    else
        print_status "ERROR" "❌ $failed_tests out of $total_tests tests failed"
        echo ""
        print_status "INFO" "Please review the failed tests above"
        print_status "INFO" "Check container logs: docker logs influxdb-stack-test"
    fi
    echo "=============================================="
    echo ""
    
    # Exit with appropriate code
    if [ $failed_tests -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# Error handler
handle_error() {
    print_status "ERROR" "An unexpected error occurred during configuration testing"
    restore_config
    exit 1
}

# Set up error handling
trap handle_error ERR

# Run main function
main "$@" 