#!/usr/bin/with-contenv bashio

# =============================================================================
# INFLUXDB STACK SYNC TOOLS - CONFIGURATION EXTRACTION
# =============================================================================
# PURPOSE: Extract configuration files from running InfluxDB Stack container
# USAGE:   ./sync-tools/s2_extract-configs.sh
# 
# This script extracts configuration files from either:
# 1. Test-Mode: Local influxdb-stack-test container
# 2. Addon-Mode: Remote Home Assistant addon container via SSH
#
# EXTRACTED FILES:
# - Grafana configuration (grafana.ini, datasources, dashboards)
# - InfluxDB configuration (if any config files exist)
# - NGINX configuration (nginx.conf, ingress.conf)
# - Dashboard files (JSON files from Grafana)
#
# OUTPUT: Files are organized in ./ssh-extracted-configs/ directory
# =============================================================================

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Load environment and set defaults
load_env
set_defaults

# Detect mode
MODE=$(detect_mode)

print_status() {
    local status="$1"
    local message="$2"
    case $status in
        "OK") echo -e "\033[0;32m✅ $message\033[0m" ;;
        "WARN") echo -e "\033[1;33m⚠️  $message\033[0m" ;;
        "ERROR") echo -e "\033[0;31m❌ $message\033[0m" ;;
        "INFO") echo -e "\033[0;34mℹ️  $message\033[0m" ;;
    esac
}

echo "📥 InfluxDB Stack Sync Tools - Configuration Extraction"
echo "======================================================"
echo "Mode: $MODE"
echo "Container: $(get_container_name "$MODE")"
echo ""

# Test container access
CONTAINER_NAME=$(get_container_name "$MODE")

if [ "$MODE" = "test" ]; then
    CONTAINER_ID="$CONTAINER_NAME"
    CMD_PREFIX=""
else
    SSH_CMD=$(get_ssh_connection "$MODE")
    CONTAINER_ID=$($SSH_CMD "docker ps -q --filter name=$CONTAINER_NAME" 2>/dev/null)
    CMD_PREFIX="$SSH_CMD"
fi

if [ -z "$CONTAINER_ID" ]; then
    print_status "ERROR" "Container $CONTAINER_NAME not found or not running"
    exit 1
fi

print_status "OK" "Container $CONTAINER_NAME is accessible"

# Create extraction directories
create_directories

# Create temporary extraction directory
TEMP_EXTRACT_DIR="$EXTRACTED_DIR/temp"
mkdir -p "$TEMP_EXTRACT_DIR"

print_status "INFO" "Extracting configuration files..."

# Execute extraction commands
if [ "$MODE" = "test" ]; then
    EXEC_CMD="docker exec $CONTAINER_ID"
else
    EXEC_CMD="$CMD_PREFIX docker exec $CONTAINER_ID"
fi

# Create extraction script to run in container
$EXEC_CMD bash << 'EOF'
# Create temporary directory in container
mkdir -p /tmp/extracted-configs/grafana/provisioning/dashboards
mkdir -p /tmp/extracted-configs/grafana/provisioning/datasources
mkdir -p /tmp/extracted-configs/nginx/servers
mkdir -p /tmp/extracted-configs/influxdb

echo "Extracting InfluxDB Stack configuration files..."

# Grafana files
echo "  Extracting Grafana configuration..."
cp /etc/grafana/grafana.ini /tmp/extracted-configs/grafana/ 2>/dev/null || echo '   grafana.ini not accessible'
cp /etc/grafana/provisioning/datasources/influxdb.yml /tmp/extracted-configs/grafana/provisioning/datasources/ 2>/dev/null || echo '   influxdb.yml not accessible'

# Dashboard files
echo "  Extracting dashboard files..."
cp /etc/grafana/provisioning/dashboards/*.json /tmp/extracted-configs/grafana/provisioning/dashboards/ 2>/dev/null || echo '   dashboard files not accessible'
cp /etc/grafana/provisioning/dashboards/*.yml /tmp/extracted-configs/grafana/provisioning/dashboards/ 2>/dev/null || echo '   dashboard provider files not accessible'

# NGINX files
echo "  Extracting NGINX configuration..."
cp /etc/nginx/nginx.conf /tmp/extracted-configs/nginx/ 2>/dev/null || echo '   nginx.conf not accessible'
cp /etc/nginx/servers/ingress.conf /tmp/extracted-configs/nginx/servers/ 2>/dev/null || echo '   ingress.conf not accessible'

# InfluxDB files (if any configuration files exist)
echo "  Extracting InfluxDB configuration..."
if [ -d /etc/influxdb ]; then
    cp /etc/influxdb/*.conf /tmp/extracted-configs/influxdb/ 2>/dev/null || echo '   No InfluxDB config files found'
    cp /etc/influxdb/*.yml /tmp/extracted-configs/influxdb/ 2>/dev/null || echo '   No InfluxDB YAML files found'
else
    echo '   No InfluxDB configuration directory found'
fi

echo "Extraction completed in container"
EOF

# Copy files from container to local filesystem
print_status "INFO" "Copying extracted files to local filesystem..."

# Copy Grafana files
if [ "$MODE" = "test" ]; then
    docker cp "$CONTAINER_ID:/tmp/extracted-configs/grafana/." "$EXTRACTED_DIR/grafana/" 2>/dev/null || print_status "WARN" "Could not copy some Grafana files"
    docker cp "$CONTAINER_ID:/tmp/extracted-configs/grafana/provisioning/dashboards/." "$EXTRACTED_DIR/dashboards/dashboards/" 2>/dev/null || print_status "WARN" "Could not copy dashboard files"
    docker cp "$CONTAINER_ID:/tmp/extracted-configs/grafana/provisioning/datasources/." "$EXTRACTED_DIR/grafana/datasources/" 2>/dev/null || print_status "WARN" "Could not copy datasource files"
    docker cp "$CONTAINER_ID:/tmp/extracted-configs/nginx/." "$EXTRACTED_DIR/nginx/" 2>/dev/null || print_status "WARN" "Could not copy NGINX files"
    docker cp "$CONTAINER_ID:/tmp/extracted-configs/influxdb/." "$EXTRACTED_DIR/influxdb/" 2>/dev/null || print_status "WARN" "Could not copy InfluxDB files"
else
    # For SSH mode, we need to copy files through SSH
    $SSH_CMD "docker cp $CONTAINER_ID:/tmp/extracted-configs/grafana/. /tmp/sync-grafana/" 2>/dev/null || print_status "WARN" "Could not copy Grafana files"
    $SSH_CMD "docker cp $CONTAINER_ID:/tmp/extracted-configs/nginx/. /tmp/sync-nginx/" 2>/dev/null || print_status "WARN" "Could not copy NGINX files"
    $SSH_CMD "docker cp $CONTAINER_ID:/tmp/extracted-configs/influxdb/. /tmp/sync-influxdb/" 2>/dev/null || print_status "WARN" "Could not copy InfluxDB files"
    
    # Copy from remote host to local
    scp -r "$HA_SSH_USER@$HA_HOSTNAME:/tmp/sync-grafana/*" "$EXTRACTED_DIR/grafana/" 2>/dev/null || print_status "WARN" "Could not transfer Grafana files"
    scp -r "$HA_SSH_USER@$HA_HOSTNAME:/tmp/sync-nginx/*" "$EXTRACTED_DIR/nginx/" 2>/dev/null || print_status "WARN" "Could not transfer NGINX files"
    scp -r "$HA_SSH_USER@$HA_HOSTNAME:/tmp/sync-influxdb/*" "$EXTRACTED_DIR/influxdb/" 2>/dev/null || print_status "WARN" "Could not transfer InfluxDB files"
fi

# Clean up temporary files in container
$EXEC_CMD rm -rf /tmp/extracted-configs/ 2>/dev/null || true

# Show extraction results
echo ""
print_status "INFO" "Extraction completed. Files saved to: $EXTRACTED_DIR"
echo ""
echo "📁 Extracted files:"

for dir in grafana nginx influxdb dashboards; do
    if [ -d "$EXTRACTED_DIR/$dir" ]; then
        file_count=$(find "$EXTRACTED_DIR/$dir" -type f 2>/dev/null | wc -l)
        if [ $file_count -gt 0 ]; then
            echo "  📂 $dir/: $file_count files"
            find "$EXTRACTED_DIR/$dir" -type f -exec basename {} \; | sort | sed 's/^/    - /'
        else
            echo "  📂 $dir/: (empty)"
        fi
    fi
done

echo ""
print_status "OK" "Configuration extraction completed successfully"
print_status "INFO" "Next steps:"
print_status "INFO" "  • Run s3_compare-configs.sh to compare with repository"
print_status "INFO" "  • Run s4_sync-to-repo.sh to sync changes back to repository" 