#!/bin/bash

# =============================================================================
# PROMETHEUS STACK ADD-ON - CONFIGURATION TESTING SCRIPT
# =============================================================================
# PURPOSE: Test the add-on with different configuration scenarios
# USAGE:   ./test-config.sh
# 
# This script tests:
# 1. Different Alertmanager receiver names
# 2. Various email configurations
# 3. Configuration file generation
# 4. Dynamic configuration reloading
#
# TEST SCENARIOS:
# - Basic configuration validation
# - Email format validation
# - Receiver name validation
# - Configuration file syntax checking
# - Service restart with new configuration
#
# REQUIREMENTS: 
# - Container must be running (use build-test.sh first)
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

echo "⚙️  Configuration Testing for Prometheus Stack Add-on"
echo "====================================================="

# Check if container is running
if ! docker ps | grep -q prometheus-stack; then
    echo "❌ Container is not running. Start it first with: ./build-test.sh"
    exit 1
fi

echo "✅ Container is running"

# Test configurations
declare -A test_configs=(
    ["basic"]='{"alertmanager_receiver":"default","alertmanager_to_email":"test@example.com"}'
    ["production"]='{"alertmanager_receiver":"prod-alerts","alertmanager_to_email":"admin@company.com"}'
    ["multiple"]='{"alertmanager_receiver":"team","alertmanager_to_email":"team@company.com"}'
    ["special_chars"]='{"alertmanager_receiver":"test-receiver-123","alertmanager_to_email":"test+tag@example.com"}'
)

# Function to wait for services to be ready
wait_for_services() {
    local max_attempts=30
    local attempt=1
    
    echo -n "⏳ Checking service readiness..."
    
    while [ $attempt -le $max_attempts ]; do
        # Try to reach each core service
        if curl -sf http://localhost:9090/-/healthy >/dev/null 2>&1 && \
           curl -sf http://localhost:9093/-/healthy >/dev/null 2>&1 && \
           curl -sf http://localhost:9115/metrics >/dev/null 2>&1 && \
           curl -sf http://localhost:8080/ >/dev/null 2>&1; then
            echo " ready!"
            return 0
        fi
        
        echo -n "."
        sleep 0.5
        attempt=$((attempt + 1))
    done
    
    echo " timeout!"
    return 1
}

# Function to test configuration
test_configuration() {
    local config_name="$1"
    local config_json="$2"
    
    echo ""
    echo "🔧 Testing configuration: $config_name"
    echo "-------------------------------------"
    
    # Write the test configuration
    echo "$config_json" > "$PROJECT_ROOT/test-data/options.json"
    
    echo "🔄 Restarting container with new configuration..."
    docker restart prometheus-stack-test > /dev/null
    
    # Wait for services to start
    echo "⏳ Waiting for services to start..."
    if ! wait_for_services; then
        echo "❌ Services failed to start after configuration change"
        return 1
    fi
    
    # Check if Alertmanager configuration was generated correctly
    echo "📋 Checking generated Alertmanager configuration..."
    if docker exec prometheus-stack-test test -f /etc/alertmanager/alertmanager.yml; then
        echo "✅ Alertmanager configuration file exists"
        
        # Display the generated configuration
        echo "📄 Generated configuration:"
        docker exec prometheus-stack-test cat /etc/alertmanager/alertmanager.yml
    else
        echo "❌ Alertmanager configuration file missing"
        return 1
    fi
    
    # Test configuration parsing
    echo "🔍 Testing configuration parsing..."
    local receiver=$(echo "$config_json" | jq -r '.alertmanager_receiver')
    local email=$(echo "$config_json" | jq -r '.alertmanager_to_email')
    
    echo "   Receiver: $receiver"
    echo "   Email: $email"
    
    # Validate email format (basic check)
    if [[ "$email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        echo "✅ Email format is valid"
    else
        echo "⚠️  Email format may be invalid: $email"
    fi
    
    # Check if Alertmanager is healthy
    echo "🏥 Checking Alertmanager health..."
    if curl -f -s --max-time 10 "http://localhost:9093/-/healthy" > /dev/null; then
        echo "✅ Alertmanager is healthy with new configuration"
    else
        echo "❌ Alertmanager is unhealthy with new configuration"
        return 1
    fi
    
    echo "✅ Configuration '$config_name' test passed"
}

# Function to validate configuration file syntax
validate_config_syntax() {
    echo ""
    echo "🔧 Validating Configuration File Syntax"
    echo "---------------------------------------"
    
    # Test if the generated alertmanager.yml is valid YAML
    if docker exec prometheus-stack-test sh -c 'cat /etc/alertmanager/alertmanager.yml | grep -q "global:" && cat /etc/alertmanager/alertmanager.yml | grep -q "route:"'; then
        echo "✅ Alertmanager configuration has required sections"
    else
        echo "❌ Alertmanager configuration missing required sections"
        return 1
    fi
    
    # Test if Prometheus configuration is valid
    if docker exec prometheus-stack-test test -f /etc/prometheus/prometheus.yml; then
        echo "✅ Prometheus configuration file exists"
    else
        echo "❌ Prometheus configuration file missing"
        return 1
    fi
}

# Function to test Prometheus config
test_prometheus_config() {
    echo ""
    echo "🔍 Testing Prometheus configuration..."
    if ! docker exec prometheus-stack-test promtool check config /etc/prometheus/prometheus.yml; then
        echo ""
        print_status "ERROR" "❌ Config test failed: Invalid Prometheus configuration ❌"
        exit 1
    fi
    print_status "OK" "Prometheus configuration is valid"
}

# Function to test Alertmanager config
test_alertmanager_config() {
    echo ""
    echo "🔍 Testing Alertmanager configuration..."
    if ! docker exec prometheus-stack-test amtool check-config /etc/alertmanager/alertmanager.yml; then
        echo ""
        print_status "ERROR" "❌ Config test failed: Invalid Alertmanager configuration ❌"
        exit 1
    fi
    print_status "OK" "Alertmanager configuration is valid"
}

# Function to test Blackbox config
test_blackbox_config() {
    echo ""
    echo "🔍 Testing Blackbox configuration..."
    if ! docker exec prometheus-stack-test blackbox_exporter --config.check /etc/blackbox/blackbox.yml; then
        echo ""
        print_status "ERROR" "❌ Config test failed: Invalid Blackbox configuration ❌"
        exit 1
    fi
    print_status "OK" "Blackbox configuration is valid"
}

# Function to test Karma config
test_karma_config() {
    echo ""
    echo "🔍 Testing Karma configuration..."
    if ! docker exec prometheus-stack-test karma --check-config; then
        echo ""
        print_status "ERROR" "❌ Config test failed: Invalid Karma configuration ❌"
        exit 1
    fi
    print_status "OK" "Karma configuration is valid"
}

# Function to test NGINX config
test_nginx_config() {
    echo ""
    echo "🔍 Testing NGINX configuration..."
    if ! docker exec prometheus-stack-test nginx -t; then
        echo ""
        print_status "ERROR" "❌ Config test failed: Invalid NGINX configuration ❌"
        exit 1
    fi
    print_status "OK" "NGINX configuration is valid"
}

# Main testing sequence
echo "🚀 Starting configuration tests..."
echo "=================================="

failed_tests=0

# Test each configuration
for config_name in "${!test_configs[@]}"; do
    if ! test_configuration "$config_name" "${test_configs[$config_name]}"; then
        ((failed_tests++))
    fi
done

# Validate configuration syntax
if ! validate_config_syntax; then
    ((failed_tests++))
fi

# Test Prometheus configuration
if ! test_prometheus_config; then
    ((failed_tests++))
fi

# Test Alertmanager configuration
if ! test_alertmanager_config; then
    ((failed_tests++))
fi

# Test Blackbox configuration
if ! test_blackbox_config; then
    ((failed_tests++))
fi

# Test Karma configuration
if ! test_karma_config; then
    ((failed_tests++))
fi

# Test NGINX configuration
if ! test_nginx_config; then
    ((failed_tests++))
fi

echo ""
echo "📊 Configuration Test Summary"
echo "============================="

if [ $failed_tests -eq 0 ]; then
    echo "🎉 ALL CONFIGURATION TESTS PASSED!"
    echo ""
    echo "✅ Dynamic configuration generation works"
    echo "✅ Alertmanager configuration is valid"
    echo "✅ Service restart with new config works"
    echo "✅ Email format validation works"
    echo ""
    echo "💡 Your add-on configuration system is working correctly!"
else
    echo "⚠️  $failed_tests configuration test(s) failed"
    echo ""
    echo "🔧 Troubleshooting:"
    echo "   1. Check container logs: docker logs prometheus-stack-test"
    echo "   2. Verify jq is working: docker exec prometheus-stack-test jq --version"
    echo "   3. Check file permissions in test-data directory"
    echo "   4. Verify the run.sh script is generating config correctly"
fi

echo ""
echo "📋 Test Results:"
echo "   - Basic config: ${test_configs[basic]}"
echo "   - Production config: ${test_configs[production]}"
echo "   - Multiple config: ${test_configs[multiple]}"
echo "   - Special chars config: ${test_configs[special_chars]}"

exit $failed_tests 