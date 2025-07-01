#!/bin/bash
# extract-configs.sh - Extract ALL configuration files (works in both test and addon mode)

# Auto-detect mode based on container name
if docker ps --filter 'name=prometheus-stack-test' --format '{{.Names}}' | grep -q prometheus-stack-test 2>/dev/null; then
    echo "🧪 Test mode detected (local container)"
    HA_IP="localhost"
    CONTAINER_FILTER="prometheus-stack-test"
    CMD_PREFIX=""
    COPY_METHOD="local"
else
    echo "🏠 Addon mode detected (remote Home Assistant)"
    HA_IP="homeassistant.local"
    CONTAINER_FILTER="prometheus"
    CMD_PREFIX="ssh root@$HA_IP"
    COPY_METHOD="scp"
fi

echo "📥 Extracting ALL configuration files..."
echo "Target: $HA_IP (container filter: $CONTAINER_FILTER)"
echo "==============================================="

# Create local directories
mkdir -p ssh-extracted-configs/{dashboards,prometheus,grafana,blackbox,alerting}

# Execute extraction commands (locally or via SSH)
$CMD_PREFIX bash << EOF
echo '🔍 Finding prometheus container...'
CONTAINER_ID=\$(docker ps --filter 'name=$CONTAINER_FILTER' --format '{{.ID}}' | head -1)

if [ -z "\$CONTAINER_ID" ]; then
    echo '❌ No prometheus container found!'
    [ "$CONTAINER_FILTER" = "prometheus-stack-test" ] && echo 'Run ./test/build-test.sh first to start the test container'
    exit 1
fi

echo '📦 Container found: '\$CONTAINER_ID

# Create temp extraction directory
mkdir -p /tmp/extracted-configs/{dashboards,prometheus,grafana,blackbox,alerting}

echo '📊 Extracting Grafana dashboards...'
docker cp "\$CONTAINER_ID:/etc/grafana/provisioning/dashboards/" "/tmp/extracted-configs/dashboards/" 2>/dev/null || echo '   Dashboards not accessible'

echo '🎯 Extracting Prometheus config...'
docker cp "\$CONTAINER_ID:/etc/prometheus/prometheus.yml" "/tmp/extracted-configs/prometheus/" 2>/dev/null || echo '   prometheus.yml not accessible'
docker cp "\$CONTAINER_ID:/etc/prometheus/rules/" "/tmp/extracted-configs/prometheus/" 2>/dev/null || echo '   Alert rules not accessible'

echo '📊 Extracting Grafana config...'
docker cp "\$CONTAINER_ID:/etc/grafana/grafana.ini" "/tmp/extracted-configs/grafana/" 2>/dev/null || echo '   grafana.ini not accessible'
docker cp "\$CONTAINER_ID:/etc/grafana/provisioning/" "/tmp/extracted-configs/grafana/" 2>/dev/null || echo '   Grafana provisioning not accessible'

echo '🔎 Extracting Blackbox exporter config...'
docker cp "\$CONTAINER_ID:/etc/blackbox_exporter/blackbox.yml" "/tmp/extracted-configs/blackbox/" 2>/dev/null || echo '   blackbox.yml not accessible'

echo '🚨 Extracting Alertmanager config...'
docker cp "\$CONTAINER_ID:/etc/alertmanager/alertmanager.yml" "/tmp/extracted-configs/alerting/" 2>/dev/null || echo '   alertmanager.yml not accessible'

echo '📋 Extracted files summary:'
find /tmp/extracted-configs -type f 2>/dev/null | head -10
echo '   ... (showing first 10 files)'
EOF

# Copy files to local directory (method depends on local vs remote)
echo "📥 Copying to local directory..."
if [ "$COPY_METHOD" = "local" ]; then
    cp -r /tmp/extracted-configs/* "./ssh-extracted-configs/" 2>/dev/null
    rm -rf /tmp/extracted-configs
else
    scp -r "root@$HA_IP:/tmp/extracted-configs/*" "./ssh-extracted-configs/" 2>/dev/null
    ssh "root@$HA_IP" "rm -rf /tmp/extracted-configs"
fi

# Show results
echo ""
echo "✅ Configuration extraction complete!"
echo "📁 Files saved to: ./ssh-extracted-configs/"
echo ""
echo "📋 What was extracted:"
echo "   📊 Dashboards: $(find ./ssh-extracted-configs/dashboards -name "*.json" 2>/dev/null | wc -l) files"
echo "   🎯 Prometheus: $(find ./ssh-extracted-configs/prometheus -type f 2>/dev/null | wc -l) files"
echo "   📊 Grafana: $(find ./ssh-extracted-configs/grafana -type f 2>/dev/null | wc -l) files"
echo "   🔎 Blackbox: $(find ./ssh-extracted-configs/blackbox -type f 2>/dev/null | wc -l) files"
echo "   🚨 Alerting: $(find ./ssh-extracted-configs/alerting -type f 2>/dev/null | wc -l) files"

echo ""
echo "🔍 Compare with current files:"
echo "   Source files: ./dashboards/, ./prometheus-stack/rootfs/etc/"
echo "   Runtime files: ./prometheus-stack/rootfs/etc/{prometheus,grafana,blackbox_exporter}/"
echo "   Extracted files: ./ssh-extracted-configs/"

if [ "$COPY_METHOD" = "local" ]; then
    echo ""
    echo "🧪 Test mode notes:"
    echo "   - Container: $CONTAINER_FILTER"
    echo "   - Config source: ../test-data/options.json"
    echo "   - To restart with new config: docker restart $CONTAINER_FILTER"
fi 