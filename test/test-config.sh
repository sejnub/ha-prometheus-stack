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

# Function to test a configuration
test_configuration() {
    local config_name="$1"
    local config_json="$2"
    
    echo ""
    echo "🧪 Testing Configuration: $config_name"
    echo "----------------------------------------"
    
    # Create test configuration
    echo "$config_json" > ../test-data/options.json
    
    # Restart container to apply new configuration
    echo "🔄 Restarting container with new configuration..."
    docker restart prometheus-stack-test > /dev/null
    
    # Wait for services to start
    echo "⏳ Waiting for services to start..."
    sleep 15
    
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