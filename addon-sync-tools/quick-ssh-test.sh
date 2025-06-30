#!/bin/bash
# quick-ssh-test.sh - Test SSH access to prometheus files

HA_IP="homeassistant.local"
HA_USER="root"

echo "🔍 Testing SSH access to prometheus configuration files..."
echo "========================================================"

ssh "$HA_USER@$HA_IP" "
echo '🐳 1. Container Status:'
docker ps --filter 'name=prometheus' --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'

echo ''
echo '📊 2. Configuration Files Access:'
CONTAINER_ID=\$(docker ps --filter 'name=prometheus' --format '{{.ID}}' | head -1)
if [ -n \"\$CONTAINER_ID\" ]; then
    echo '✅ Container found: '\$CONTAINER_ID
    echo ''
    echo 'Configuration access test:'
    echo '  📊 Dashboards:'
    docker exec \$CONTAINER_ID ls /etc/grafana/provisioning/dashboards/*.json 2>/dev/null | wc -l | xargs -I {} echo '    {} dashboard files found'
    echo '  🎯 Prometheus:'
    docker exec \$CONTAINER_ID ls /etc/prometheus/prometheus.yml 2>/dev/null && echo '    prometheus.yml accessible' || echo '    prometheus.yml not accessible'
    echo '  📊 Grafana:'
    docker exec \$CONTAINER_ID ls /etc/grafana/grafana.ini 2>/dev/null && echo '    grafana.ini accessible' || echo '    grafana.ini not accessible'
    echo '  🔎 Blackbox:'
    docker exec \$CONTAINER_ID ls /etc/blackbox_exporter/blackbox.yml 2>/dev/null && echo '    blackbox.yml accessible' || echo '    blackbox.yml not accessible'
    echo '  🚨 Alertmanager:'
    docker exec \$CONTAINER_ID ls /etc/alertmanager/alertmanager.yml 2>/dev/null && echo '    alertmanager.yml accessible' || echo '    alertmanager.yml not accessible'
else
    echo '❌ No prometheus container running'
fi

echo ''
echo '📁 3. Host-side Addon Data (checking anyway):'
ls -la /addon_configs/ | grep prometheus || echo '❌ No addon_configs found (expected - addon uses container storage)'
ls -la /data/ | grep prometheus || echo '❌ No data directories found'
ls -la /share/ | grep prometheus || echo '❌ No share directories found'

echo ''
echo '📡 4. API Access Test:'
curl -s -m 5 http://localhost:3000/api/health 2>/dev/null && echo '✅ Grafana API accessible' || echo '⚠️ Grafana API not accessible from SSH host'
"

echo ""
echo "🎯 Next Steps:"
echo "- ✅ Container found: Use SSH Container Access (ONLY option for this addon)"
echo "- ✅ API accessible: Can also use SSH + API Combo for comprehensive sync"  
echo "- ❌ No addon_configs: This addon stores everything in container (not on host)"
echo ""
echo "📋 Recommended workflow:"
echo "   1. Run ./extract-configs.sh to get ALL current configuration files"
echo "   2. Run ./compare-configs.sh to see what changed"
echo "   3. Manually copy desired changes to git repository" 