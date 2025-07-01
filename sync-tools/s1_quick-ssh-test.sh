#!/bin/bash
# quick-ssh-test.sh - Test access to prometheus files (works locally and remotely)

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Load configuration and detect mode
load_env
set_defaults
MODE=$(detect_mode)

if [ "$MODE" = "test" ]; then
    echo "Test mode detected (local container)"
    HA_IP="localhost"
    CONTAINER_FILTER="$LOCAL_CONTAINER_NAME"
    CMD_PREFIX=""
else
    echo "Addon mode detected (remote Home Assistant)"
    HA_IP="$HA_HOSTNAME"
    CONTAINER_FILTER="$REMOTE_CONTAINER_NAME"
    CMD_PREFIX=$(get_ssh_prefix "addon")
fi

# Show configuration
show_config "$MODE"

echo "Testing access to prometheus configuration files..."
echo "Target: $HA_IP (container filter: $CONTAINER_FILTER)"
echo "========================================================"

# Execute commands (locally or via SSH)
$CMD_PREFIX bash << EOF
echo '1. Container Status:'
docker ps --filter 'name=$CONTAINER_FILTER' --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'

echo ''
echo '📁 2. Configuration Files Access:'
CONTAINER_ID=\$(docker ps --filter 'name=$CONTAINER_FILTER' --format '{{.ID}}' | head -1)
if [ -n "\$CONTAINER_ID" ]; then
    echo 'Container found: '\$CONTAINER_ID
    echo ''
    echo 'Configuration access test:'
    echo '  Dashboards:'
    docker exec \$CONTAINER_ID find /etc/grafana/provisioning/dashboards -name "*.json" -type f 2>/dev/null | wc -l | xargs -I {} echo '    {} dashboard files found'
    echo '  Prometheus:'
    docker exec \$CONTAINER_ID ls /etc/prometheus/prometheus.yml 2>/dev/null && echo '    ✅ prometheus.yml accessible' || echo '    ❌ prometheus.yml not accessible'
    echo '  Grafana:'
    docker exec \$CONTAINER_ID ls /etc/grafana/grafana.ini 2>/dev/null && echo '    ✅ grafana.ini accessible' || echo '    ❌ grafana.ini not accessible'
    echo '  Blackbox:'
    docker exec \$CONTAINER_ID ls /etc/blackbox_exporter/blackbox.yml 2>/dev/null && echo '    ✅ blackbox.yml accessible' || echo '    ❌ blackbox.yml not accessible'
    echo '  Alertmanager:'
    docker exec \$CONTAINER_ID ls /etc/alertmanager/alertmanager.yml 2>/dev/null && echo '    ✅ alertmanager.yml accessible' || echo '    ❌ alertmanager.yml not accessible'
else
    echo '❌ No $CONTAINER_FILTER container running'
fi


EOF

# Local-specific checks (only run locally)
if [ -z "$CMD_PREFIX" ]; then
    echo ''
    echo '4. Local Test Data:'
    if [ -d "$SCRIPT_DIR/../test-data" ]; then
        echo "Test data directory found: $SCRIPT_DIR/../test-data"
        ls -la "$SCRIPT_DIR/../test-data/" | head -5
    else
        echo 'No test-data directory found'
    fi
else
    # Remote-specific checks (only run via SSH)
    $CMD_PREFIX bash << 'EOF'
echo ''
echo '4. Host-side Addon Data:'
ls -la /addon_configs/ | grep prometheus || echo 'No addon_configs found (expected - addon uses container storage)'
ls -la /data/ | grep prometheus || echo 'No data directories found'
ls -la /share/ | grep prometheus || echo 'No share directories found'
EOF
fi

echo ""
echo "Next Steps:"
if [ -z "$CMD_PREFIX" ]; then
    echo "- Local container found: Direct Docker access available"
    echo "- Test mode: Can extract configs directly from local container"
    echo "- Test data: Configuration stored in ../test-data/"
else
    echo "- Container found: Use SSH Container Access (ONLY option for this addon)"
    echo "- API accessible: Can also use SSH + API Combo for comprehensive sync"  
    echo "- No addon_configs: This addon stores everything in container (not on host)"
fi
echo ""
echo "Recommended workflow:"
echo "   1. Run ./s2_extract-configs.sh to get ALL current configuration files"
echo "   2. Run ./s3_compare-configs.sh to see what changed"
echo "   3. Run ./s4_sync-to-repo.sh to automatically sync changes to git repository"

# Check if container was found and provide summary
if [ -z "$CMD_PREFIX" ]; then
    # Local mode - check if container exists
    if docker ps --filter "name=$CONTAINER_FILTER" --format '{{.Names}}' | grep -q "$CONTAINER_FILTER"; then
        print_status_icon "OK" "Quick SSH test completed successfully - Local container accessible"
    else
        print_status_icon "ERROR" "Quick SSH test failed - No local container found"
        exit 1
    fi
else
    # Remote mode - check if we can connect
    if timeout 5 $CMD_PREFIX "echo 'SSH test'" >/dev/null 2>&1; then
        print_status_icon "OK" "Quick SSH test completed successfully - Remote connection established"
    else
        print_status_icon "ERROR" "Quick SSH test failed - Cannot connect to remote host"
        exit 1
    fi
fi 