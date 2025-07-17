#!/bin/bash

# =============================================================================
# ADDON CONFIGURATION SYNC TOOLS - CONFIGURATION LIBRARY
# =============================================================================
# PURPOSE: Centralized configuration management for InfluxDB Stack sync tools
# USAGE:   source config.sh (from other scripts)
# 
# This script provides:
# 1. Environment variable loading from .env file
# 2. Default configuration values
# 3. Mode detection (test vs addon)
# 4. Centralized path definitions
# 5. SSH connection management
#
# CONFIGURATION PRECEDENCE:
# 1. .env file values
# 2. Environment variables
# 3. Default values
# =============================================================================

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment variables from .env file
load_env() {
    local env_file="$SCRIPT_DIR/.env"
    if [ -f "$env_file" ]; then
        echo "Loading configuration from $env_file"
        set -a  # automatically export all variables
        source "$env_file"
        set +a  # turn off automatic export
    else
        echo "⚠️ No .env file found, using defaults"
    fi
}

# Function to detect if we're in test mode or addon mode
detect_mode() {
    if docker ps --filter 'name=influxdb-stack-test' | grep -q influxdb-stack-test; then
        echo "test"
    else
        echo "addon"
    fi
}

# Function to get SSH connection prefix
get_ssh_prefix() {
    local mode="$1"
    if [ "$mode" = "test" ]; then
        echo ""  # No SSH prefix for test mode
    else
        echo "ssh ${HA_SSH_USER}@${HA_HOSTNAME}"
    fi
}

# Function to get container name based on mode
get_container_name() {
    local mode="$1"
    if [ "$mode" = "test" ]; then
        echo "$LOCAL_CONTAINER_NAME"
    else
        echo "$REMOTE_CONTAINER_NAME"
    fi
}

# Function to show current configuration
show_config() {
    local mode="$1"
    echo "Configuration:"
    echo "  Mode: $mode"
    echo "  Container: $(get_container_name "$mode")"
    echo "  Extraction dir: $EXTRACTED_DIR"
    echo "  Runtime dir: $RUNTIME_DIR"
    echo "  Verbose: $VERBOSE"
    echo "  Dry run: $DRY_RUN"
}

# Function to get extraction directories
get_extraction_dirs() {
    echo "dashboards grafana influxdb nginx"
}

# Set default configuration values
set_defaults() {
    # Home Assistant Connection Settings
    export HA_HOSTNAME="${HA_HOSTNAME:-homeassistant.local}"
    export HA_SSH_USER="${HA_SSH_USER:-root}"
    export HA_SSH_PORT="${HA_SSH_PORT:-22}"
    export HA_SSH_KEY="${HA_SSH_KEY:-~/.ssh/id_rsa}"
    export HA_SSH_PASSWORD="${HA_SSH_PASSWORD:-}"
    
    # Container Settings
    export LOCAL_CONTAINER_NAME="${LOCAL_CONTAINER_NAME:-influxdb-stack-test}"
    export REMOTE_CONTAINER_NAME="${REMOTE_CONTAINER_NAME:-addon_local_influxdb_stack}"
    
    # Sync Settings
    export SYNC_BACKUP_DIR="${SYNC_BACKUP_DIR:-./sync-backups}"
    export EXTRACTED_DIR="${EXTRACTED_DIR:-./ssh-extracted-configs}"
    export RUNTIME_DIR="${RUNTIME_DIR:-./influxdb-stack/rootfs/etc}"
    export VERBOSE="${VERBOSE:-true}"  # Temporarily set to true for debugging
    export DRY_RUN="${DRY_RUN:-false}"
    
    # =============================================================================
    # CENTRALIZED PATH DEFINITIONS
    # =============================================================================
    # All paths used throughout the sync tools - NO MORE HARDCODING!
    
    # Source paths (git repository)
    export SOURCE_ROOT="./influxdb-stack"
    export SOURCE_ROOTFS="$SOURCE_ROOT/rootfs/etc"
    export SOURCE_TEMPLATES="$SOURCE_ROOT"  # For template files like grafana.ini
    
    # Container runtime paths
    export CONTAINER_ETC="/etc"
    export CONTAINER_INFLUXDB="$CONTAINER_ETC/influxdb"
    export CONTAINER_GRAFANA="$CONTAINER_ETC/grafana"
    export CONTAINER_NGINX="$CONTAINER_ETC/nginx"
    
    # Extraction temporary paths
    export EXTRACT_TEMP="/tmp/extracted-configs"
}

# Function to detect environment mode
detect_environment() {
    if docker ps --filter 'name=influxdb-stack-test' | grep -q influxdb-stack-test; then
        echo "test"
    else
        echo "addon"
    fi
}

# Function to get SSH connection string
get_ssh_connection() {
    local mode="$1"
    if [ "$mode" = "test" ]; then
        echo ""  # No SSH needed for test mode
    else
        if [ -n "$HA_SSH_KEY" ] && [ -f "$HA_SSH_KEY" ]; then
            echo "ssh -i $HA_SSH_KEY ${HA_SSH_USER}@${HA_HOSTNAME}"
        else
            echo "ssh ${HA_SSH_USER}@${HA_HOSTNAME}"
        fi
    fi
}

# Function to validate configuration
validate_config() {
    local mode="$1"
    
    if [ "$mode" = "addon" ]; then
        # Check SSH connectivity for addon mode
        if ! ping -c 1 "$HA_HOSTNAME" >/dev/null 2>&1; then
            echo "❌ Cannot reach $HA_HOSTNAME"
            return 1
        fi
        
        # Test SSH connection
        if ! timeout 5 ssh -o ConnectTimeout=5 -o BatchMode=yes "${HA_SSH_USER}@${HA_HOSTNAME}" exit 2>/dev/null; then
            echo "❌ Cannot SSH to ${HA_SSH_USER}@${HA_HOSTNAME}"
            return 1
        fi
    fi
    
    return 0
}

# Function to create required directories
create_directories() {
    mkdir -p "$EXTRACTED_DIR"
    mkdir -p "$SYNC_BACKUP_DIR"
    
    # Create subdirectories for each extraction category
    local dirs=($(get_extraction_dirs))
    for dir in "${dirs[@]}"; do
        mkdir -p "$EXTRACTED_DIR/$dir"
    done
}

# Function to cleanup temporary files
cleanup_temp() {
    if [ -d "$EXTRACT_TEMP" ]; then
        rm -rf "$EXTRACT_TEMP"
    fi
}

# Export functions for use in other scripts
export -f load_env
export -f set_defaults
export -f detect_mode
export -f get_ssh_prefix
export -f get_container_name
export -f show_config
export -f get_extraction_dirs
export -f detect_environment
export -f get_ssh_connection
export -f validate_config
export -f create_directories
export -f cleanup_temp 