#!/bin/bash
# extract-configs.sh - SSH extraction of ALL configuration files

HA_IP="homeassistant.local"
HA_USER="root"

echo "📥 Extracting ALL configuration files via SSH..."
echo "==============================================="

# Create local directories
mkdir -p ssh-extracted-configs/{dashboards,prometheus,grafana,blackbox,alerting}

# SSH command to extract from container
ssh "$HA_USER@$HA_IP" "
echo '🔍 Finding prometheus container...'
CONTAINER_ID=\$(docker ps --filter 'name=prometheus' --format '{{.ID}}' | head -1)

if [ -z \"\$CONTAINER_ID\" ]; then
    echo '❌ No prometheus container found!'
    exit 1
fi

echo '📦 Container found: '\$CONTAINER_ID

# Create temp extraction directory
mkdir -p /tmp/extracted-configs/{dashboards,prometheus,grafana,blackbox,alerting}

echo '📊 Extracting Grafana dashboards...'
docker cp \"\$CONTAINER_ID:/etc/grafana/provisioning/dashboards/\" \"/tmp/extracted-configs/dashboards/\" 2>/dev/null || echo '   Dashboards not accessible'

echo '🎯 Extracting Prometheus config...'
docker cp \"\$CONTAINER_ID:/etc/prometheus/prometheus.yml\" \"/tmp/extracted-configs/prometheus/\" 2>/dev/null || echo '   prometheus.yml not accessible'
docker cp \"\$CONTAINER_ID:/etc/prometheus/rules/\" \"/tmp/extracted-configs/prometheus/\" 2>/dev/null || echo '   Alert rules not accessible'

echo '📊 Extracting Grafana config...'
docker cp \"\$CONTAINER_ID:/etc/grafana/grafana.ini\" \"/tmp/extracted-configs/grafana/\" 2>/dev/null || echo '   grafana.ini not accessible'
docker cp \"\$CONTAINER_ID:/etc/grafana/provisioning/\" \"/tmp/extracted-configs/grafana/\" 2>/dev/null || echo '   Grafana provisioning not accessible'

echo '🔎 Extracting Blackbox exporter config...'
docker cp \"\$CONTAINER_ID:/etc/blackbox_exporter/blackbox.yml\" \"/tmp/extracted-configs/blackbox/\" 2>/dev/null || echo '   blackbox.yml not accessible'

echo '🚨 Extracting Alertmanager config...'
docker cp \"\$CONTAINER_ID:/etc/alertmanager/alertmanager.yml\" \"/tmp/extracted-configs/alerting/\" 2>/dev/null || echo '   alertmanager.yml not accessible'

echo '📋 Extracted files summary:'
find /tmp/extracted-configs -type f 2>/dev/null | head -10
echo '   ... (showing first 10 files)'
"

# Copy files to local machine
echo "📥 Copying to local machine..."
scp -r "$HA_USER@$HA_IP:/tmp/extracted-configs/*" "./ssh-extracted-configs/" 2>/dev/null

# Cleanup remote temp files
ssh "$HA_USER@$HA_IP" "rm -rf /tmp/extracted-configs"

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