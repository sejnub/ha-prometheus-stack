#!/bin/bash
# config.sh - Common configuration for sync tools

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to print status with icons (like test tools)
print_status_icon() {
    local status="$1"
    local message="$2"
    case $status in
        "OK") echo -e "${GREEN}✅ $message${NC}" ;;
        "WARN") echo -e "${YELLOW}⚠️  $message${NC}" ;;
        "ERROR") echo -e "${RED}❌ $message${NC}" ;;
        "INFO") echo -e "${BLUE}ℹ️  $message${NC}" ;;
    esac
}

# Function to load environment variables from .env file
load_env() {
    local env_file="$(dirname "$0")/.env"
    
    if [ -f "$env_file" ]; then
        print_status "$BLUE" "📁 Loading configuration from: $env_file"
        
        # Read .env file and export variables
        while IFS= read -r line; do
            # Skip comments and empty lines
            [[ $line =~ ^[[:space:]]*# ]] && continue
            [[ -z $line ]] && continue
            
            # Parse key=value pairs
            if [[ $line =~ ^([^=]+)=(.*)$ ]]; then
                local key="${BASH_REMATCH[1]}"
                local value="${BASH_REMATCH[2]}"
                
                # Remove quotes if present
                value="${value%\"}"
                value="${value#\"}"
                value="${value%\'}"
                value="${value#\'}"
                
                # Export the variable
                export "$key"="$value"
            fi
        done < "$env_file"
        
        print_status "$GREEN" "✅ Configuration loaded successfully"
    else
        print_status "$YELLOW" "⚠️  No .env file found, using defaults"
    fi
}

# Set default values for all configuration variables
set_defaults() {
    # Home Assistant Connection Settings
    export HA_HOSTNAME="${HA_HOSTNAME:-homeassistant.local}"
    export HA_SSH_USER="${HA_SSH_USER:-root}"
    export HA_SSH_PORT="${HA_SSH_PORT:-22}"
    export HA_SSH_KEY="${HA_SSH_KEY:-~/.ssh/id_rsa}"
    export HA_SSH_PASSWORD="${HA_SSH_PASSWORD:-}"
    
    # Container Settings
    export LOCAL_CONTAINER_NAME="${LOCAL_CONTAINER_NAME:-prometheus-stack-test}"
    export REMOTE_CONTAINER_NAME="${REMOTE_CONTAINER_NAME:-prometheus}"
    
    # Sync Settings
    export SYNC_BACKUP_DIR="${SYNC_BACKUP_DIR:-./sync-backups}"
    export EXTRACTED_DIR="${EXTRACTED_DIR:-./ssh-extracted-configs}"
    export VERBOSE="${VERBOSE:-false}"
    export DRY_RUN="${DRY_RUN:-false}"
}

# Function to detect environment mode
detect_mode() {
    if docker ps --filter "name=$LOCAL_CONTAINER_NAME" --format '{{.Names}}' | grep -q "$LOCAL_CONTAINER_NAME" 2>/dev/null; then
        echo "test"
    else
        echo "addon"
    fi
}

# Function to get SSH command prefix based on configuration
get_ssh_prefix() {
    local mode="$1"
    
    if [ "$mode" = "addon" ]; then
        local ssh_opts=""
        
        # Add port if not default
        if [ "$HA_SSH_PORT" != "22" ]; then
            ssh_opts="$ssh_opts -p $HA_SSH_PORT"
        fi
        
        # Add key if specified and exists
        if [ -n "$HA_SSH_KEY" ] && [ -f "$HA_SSH_KEY" ]; then
            ssh_opts="$ssh_opts -i $HA_SSH_KEY"
        fi
        
        echo "ssh $ssh_opts $HA_SSH_USER@$HA_HOSTNAME"
    else
        echo ""
    fi
}

# Function to get SCP command prefix based on configuration
get_scp_prefix() {
    local mode="$1"
    
    if [ "$mode" = "addon" ]; then
        local scp_opts=""
        
        # Add port if not default
        if [ "$HA_SSH_PORT" != "22" ]; then
            scp_opts="$scp_opts -P $HA_SSH_PORT"
        fi
        
        # Add key if specified and exists
        if [ -n "$HA_SSH_KEY" ] && [ -f "$HA_SSH_KEY" ]; then
            scp_opts="$scp_opts -i $HA_SSH_KEY"
        fi
        
        echo "scp $scp_opts"
    else
        echo "cp"
    fi
}

# Function to get container filter based on mode
get_container_filter() {
    local mode="$1"
    
    if [ "$mode" = "test" ]; then
        echo "$LOCAL_CONTAINER_NAME"
    else
        echo "$REMOTE_CONTAINER_NAME"
    fi
}

# Function to validate configuration
validate_config() {
    local mode="$1"
    
    if [ "$mode" = "addon" ]; then
        # Validate SSH connection
        local ssh_cmd=$(get_ssh_prefix "addon")
        if ! timeout 5 $ssh_cmd "echo 'SSH connection test'" >/dev/null 2>&1; then
            print_status "$RED" "❌ SSH connection failed to $HA_SSH_USER@$HA_HOSTNAME:$HA_SSH_PORT"
            print_status "$YELLOW" "💡 Check your .env configuration and SSH connectivity"
            return 1
        fi
    fi
    
    return 0
}

# Function to show current configuration
show_config() {
    local mode="$1"
    
    print_status "$BLUE" "🔧 Current Configuration:"
    print_status "$BLUE" "========================="
    print_status "$BLUE" "Mode: $mode"
    print_status "$BLUE" "Container: $(get_container_filter "$mode")"
    
    if [ "$mode" = "addon" ]; then
        print_status "$BLUE" "SSH: $HA_SSH_USER@$HA_HOSTNAME:$HA_SSH_PORT"
        if [ -n "$HA_SSH_KEY" ] && [ -f "$HA_SSH_KEY" ]; then
            print_status "$BLUE" "SSH Key: $HA_SSH_KEY"
        else
            print_status "$BLUE" "SSH Key: Not configured or not found"
        fi
    fi
    
    print_status "$BLUE" "Extracted Dir: $EXTRACTED_DIR"
    print_status "$BLUE" "Backup Dir: $SYNC_BACKUP_DIR"
    print_status "$BLUE" "Verbose: $VERBOSE"
    print_status "$BLUE" "Dry Run: $DRY_RUN"
    print_status "$BLUE" ""
}

# Load configuration when this script is sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    load_env
    set_defaults
fi 