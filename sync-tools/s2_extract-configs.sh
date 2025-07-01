#!/bin/bash
# extract-configs.sh - Extract ALL configuration files (works in both test and addon mode)

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Load configuration and detect mode
load_env
set_defaults
MODE=$(detect_mode)

if [ "$MODE" = "test" ]; then
    echo "🧪 Test-Mode detected (local container)"
    HA_IP="localhost"
    CONTAINER_FILTER="$LOCAL_CONTAINER_NAME"
    CMD_PREFIX=""
    COPY_METHOD="local"
else
    echo "🏠 Addon-Mode detected (remote Home Assistant)"
    HA_IP="$HA_HOSTNAME"
    CONTAINER_FILTER="$REMOTE_CONTAINER_NAME"
    CMD_PREFIX=$(get_ssh_prefix "addon")
    COPY_METHOD="scp"
fi

# Show configuration
show_config "$MODE"

echo "Extracting ALL configuration files..."
echo "Target: $HA_IP (container filter: $CONTAINER_FILTER)"
echo "==============================================="

# Create local directories
mkdir -p "$EXTRACTED_DIR"/{dashboards,prometheus,grafana,blackbox,alerting}

# Execute extraction commands (locally or via SSH)
$CMD_PREFIX bash << EOF
echo 'Finding prometheus container...'
CONTAINER_ID=\$(docker ps --filter 'name=$CONTAINER_FILTER' --format '{{.ID}}' | head -1)

if [ -z "\$CONTAINER_ID" ]; then
    echo '❌ No prometheus container found!'
    [ "$CONTAINER_FILTER" = "prometheus-stack-test" ] && echo 'Run ./test/build.sh first to start the test container'
    exit 1
fi

echo 'Container found: '\$CONTAINER_ID

# Create temp extraction directory
mkdir -p /tmp/extracted-configs/{dashboards,prometheus,grafana,blackbox,alerting}

echo 'Extracting Grafana dashboards...'
docker cp "\$CONTAINER_ID:/etc/grafana/provisioning/dashboards/" "/tmp/extracted-configs/dashboards/" 2>/dev/null || echo '   Dashboards not accessible'

echo 'Extracting Prometheus config...'
docker cp "\$CONTAINER_ID:/etc/prometheus/prometheus.yml" "/tmp/extracted-configs/prometheus/" 2>/dev/null || echo '   prometheus.yml not accessible'
docker cp "\$CONTAINER_ID:/etc/prometheus/rules/" "/tmp/extracted-configs/prometheus/" 2>/dev/null || echo '   Alert rules not accessible'

echo 'Extracting Grafana config...'
docker cp "\$CONTAINER_ID:/etc/grafana/grafana.ini" "/tmp/extracted-configs/grafana/" 2>/dev/null || echo '   grafana.ini not accessible'
docker cp "\$CONTAINER_ID:/etc/grafana/provisioning/" "/tmp/extracted-configs/grafana/" 2>/dev/null || echo '   Grafana provisioning not accessible'

echo 'Extracting Blackbox exporter config...'
docker cp "\$CONTAINER_ID:/etc/blackbox_exporter/blackbox.yml" "/tmp/extracted-configs/blackbox/" 2>/dev/null || echo '   blackbox.yml not accessible'

echo 'Extracting Alertmanager config...'
docker cp "\$CONTAINER_ID:/etc/alertmanager/alertmanager.yml" "/tmp/extracted-configs/alerting/" 2>/dev/null || echo '   alertmanager.yml not accessible'

echo 'Extracted files summary:'
find /tmp/extracted-configs -type f 2>/dev/null | head -10
echo '   ... (showing first 10 files)'
EOF

# Copy files to local directory (method depends on local vs remote)
echo "Copying to local directory..."
if [ "$COPY_METHOD" = "local" ]; then
    cp -r /tmp/extracted-configs/* "./$EXTRACTED_DIR/" 2>/dev/null
    rm -rf /tmp/extracted-configs
else
    local scp_cmd=$(get_scp_prefix "addon")
    $scp_cmd -r "$HA_SSH_USER@$HA_IP:/tmp/extracted-configs/*" "./$EXTRACTED_DIR/" 2>/dev/null
    $CMD_PREFIX "rm -rf /tmp/extracted-configs"
fi

# Show results
echo ""
echo "✅ Configuration extraction complete!"
echo "Files saved to: ./$EXTRACTED_DIR/"
echo ""
echo "What was extracted:"
echo "   Dashboards: $(find ./$EXTRACTED_DIR/dashboards -name "*.json" 2>/dev/null | wc -l) files"
echo "   Prometheus: $(find ./$EXTRACTED_DIR/prometheus -type f 2>/dev/null | wc -l) files"
echo "   Grafana: $(find ./$EXTRACTED_DIR/grafana -type f 2>/dev/null | wc -l) files"
echo "   Blackbox: $(find ./$EXTRACTED_DIR/blackbox -type f 2>/dev/null | wc -l) files"
echo "   Alerting: $(find ./$EXTRACTED_DIR/alerting -type f 2>/dev/null | wc -l) files"

echo ""
echo "Compare with current files:"
echo "   Source files: ./dashboards/, ./prometheus-stack/rootfs/etc/"
echo "   Runtime files: ./prometheus-stack/rootfs/etc/{prometheus,grafana,blackbox_exporter}/"
echo "   Extracted files: ./$EXTRACTED_DIR/"

if [ "$COPY_METHOD" = "local" ]; then
    echo ""
    echo "Test-Mode notes:"
    echo "   - Container: $CONTAINER_FILTER"
    echo "   - Config source: ../test-data/options.json"
    echo "   - To restart with new config: docker restart $CONTAINER_FILTER"
fi

# Check if extraction was successful and provide summary
total_files=$(find ./$EXTRACTED_DIR -type f 2>/dev/null | wc -l)
if [ "$total_files" -gt 0 ]; then
    print_status_icon "OK" "Configuration extraction completed successfully - $total_files files extracted"
else
    print_status_icon "ERROR" "Configuration extraction failed - No files were extracted"
    exit 1
fi 