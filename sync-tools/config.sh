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
    export REMOTE_CONTAINER_NAME="${REMOTE_CONTAINER_NAME:-addon_local_prometheus_stack}"
    
    # Sync Settings
    export SYNC_BACKUP_DIR="${SYNC_BACKUP_DIR:-./sync-backups}"
    export EXTRACTED_DIR="${EXTRACTED_DIR:-./ssh-extracted-configs}"
    export RUNTIME_DIR="${RUNTIME_DIR:-./prometheus-stack/rootfs/etc}"
    export VERBOSE="${VERBOSE:-true}"  # Temporarily set to true for debugging
    export DRY_RUN="${DRY_RUN:-false}"
    
    # =============================================================================
    # CENTRALIZED PATH DEFINITIONS
    # =============================================================================
    # All paths used throughout the sync tools - NO MORE HARDCODING!
    
    # Source paths (git repository)
    export SOURCE_ROOT="./prometheus-stack"
    export SOURCE_ROOTFS="$SOURCE_ROOT/rootfs/etc"
    export SOURCE_TEMPLATES="$SOURCE_ROOT"  # For template files like prometheus.yml, blackbox.yml
    
    # Container runtime paths
    export CONTAINER_ETC="/etc"
    export CONTAINER_PROMETHEUS="$CONTAINER_ETC/prometheus"
    export CONTAINER_GRAFANA="$CONTAINER_ETC/grafana"
    export CONTAINER_BLACKBOX="$CONTAINER_ETC/blackbox_exporter"
    export CONTAINER_ALERTMANAGER="$CONTAINER_ETC/alertmanager"
    export CONTAINER_KARMA="$CONTAINER_ETC/karma"
    export CONTAINER_NGINX="$CONTAINER_ETC/nginx"
    
    # Extraction temporary paths
    export EXTRACT_TEMP="/tmp/extracted-configs"
}

# Function to detect environment mode
detect_mode() {
    if docker ps --filter "name=$LOCAL_CONTAINER_NAME" --format '{{.Names}}' | grep -q "$LOCAL_CONTAINER_NAME" 2>/dev/null; then
        echo "test"  # Used internally as "test" but displayed as "Test-Mode"
    else
        echo "addon"  # Used internally as "addon" but displayed as "Addon-Mode"
    fi
}

# Function to get SSH command prefix based on configuration
get_ssh_prefix() {
    local mode="$1"
    
    if [ "$mode" = "addon" ]; then  # Internal mode name
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
    if [ "$mode" = "test" ]; then
        print_status "$BLUE" "Mode: Test-Mode"
    else
        print_status "$BLUE" "Mode: Addon-Mode"
    fi
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
    # parse_config_files will be called later after it's defined
fi

# =============================================================================
# CENTRALIZED FILE CONFIGURATION SYSTEM
# =============================================================================
# Load configuration files definition from YAML file
# This eliminates redundant code and ensures consistency across all scripts

# Path to the YAML configuration file
CONFIG_FILES_YAML="$SCRIPT_DIR/config-files.yml"

# Function to parse YAML configuration (simple bash YAML parser)
parse_config_files() {
    if [ ! -f "$CONFIG_FILES_YAML" ]; then
        echo "ERROR: Configuration file not found: $CONFIG_FILES_YAML" >&2
        exit 1
    fi
    
    # This is a simple YAML parser - we'll use it to extract the configuration
    # Note: This assumes the YAML structure is consistent and well-formed
    local current_key=""
    local in_config=false
    
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$line" ]] && continue
        
        # Check if we're past the header comments
        if [[ "$line" =~ ^[[:space:]]*\".*\":$ ]] || [[ "$line" =~ ^[[:space:]]*[^[:space:]]+:$ ]]; then
            in_config=true
            # Extract the key (filename pattern)
            current_key=$(echo "$line" | sed 's/^[[:space:]]*"\?\([^"]*\)"\?:[[:space:]]*$/\1/')
            continue
        fi
        
        if [ "$in_config" = true ] && [ -n "$current_key" ]; then
            # Parse key-value pairs
            if [[ "$line" =~ ^[[:space:]]+([^:]+):[[:space:]]*(.*)$ ]]; then
                local key="${BASH_REMATCH[1]}"
                local value="${BASH_REMATCH[2]}"
                
                # Remove quotes from value
                value="${value%\"}"
                value="${value#\"}"
                
                # Store in global variables using the new property names
                case "$key" in
                    "type") declare -g "CONFIG_${current_key//[^a-zA-Z0-9]/_}_TYPE=$value" ;;
                    "runtime_path") declare -g "CONFIG_${current_key//[^a-zA-Z0-9]/_}_RUNTIME_PATH=$value" ;;
                    "source_path") declare -g "CONFIG_${current_key//[^a-zA-Z0-9]/_}_SOURCE_PATH=$value" ;;
                    "extracted_path") declare -g "CONFIG_${current_key//[^a-zA-Z0-9]/_}_EXTRACTED_PATH=$value" ;;
                    "description") declare -g "CONFIG_${current_key//[^a-zA-Z0-9]/_}_DESCRIPTION=$value" ;;
                    "priority") declare -g "CONFIG_${current_key//[^a-zA-Z0-9]/_}_PRIORITY=$value" ;;
                    "match_path") declare -g "CONFIG_${current_key//[^a-zA-Z0-9]/_}_MATCH_PATH=$value" ;;
                esac
            fi
        fi
    done < "$CONFIG_FILES_YAML"
}

# Function to get file configuration for a specific file
get_file_pattern() {
    local filename="$1"
    local file_path="$2"  # Optional: full file path for special matching
    
    # List of all patterns to check (in priority order)
    local patterns=(
        "prometheus.yml@datasources"  # Special case first
        "prometheus.yml"
        "blackbox.yml"
        "alertmanager.yml"
        "karma.yml"
        "grafana.ini"
        "nginx.conf"
        "ingress.conf"
        "dashboard-provider.yml"
        "*.json"
        "*.yml"  # Wildcard patterns last (lowest priority)
    )
    
    for pattern in "${patterns[@]}"; do
        local var_prefix="CONFIG_${pattern//[^a-zA-Z0-9]/_}"
        local type_var="${var_prefix}_TYPE"
        local runtime_var="${var_prefix}_RUNTIME_PATH"
        local source_var="${var_prefix}_SOURCE_PATH"
        local extract_var="${var_prefix}_EXTRACTED_PATH"
        local baseline_var="${var_prefix}_BASELINE_PATH"
        local match_var="${var_prefix}_MATCH_PATH"
        
        # Check if this pattern has configuration
        if [ -n "${!type_var}" ]; then
            local matches=false
            
            # Special matching for patterns with @
            if [[ "$pattern" == *"@"* ]]; then
                local base_pattern="${pattern%@*}"
                local context="${pattern#*@}"
                
                if [[ "$filename" == "$base_pattern" ]]; then
                    # Check match_path if specified
                    if [ -n "${!match_var}" ] && [ -n "$file_path" ]; then
                        if [[ "$file_path" == ${!match_var} ]]; then
                            matches=true
                        fi
                    elif [[ "$file_path" == *"$context"* ]]; then
                        matches=true
                    fi
                fi
            # Wildcard patterns
            elif [[ "$pattern" == "*."* ]]; then
                local extension="${pattern#*.}"
                if [[ "$filename" == *."$extension" ]]; then
                    matches=true
                fi
            # Exact match
            elif [[ "$filename" == "$pattern" ]]; then
                matches=true
            fi
            
            if [ "$matches" = true ]; then
                echo "${!type_var}:${!runtime_var}:${!source_var}:${!extract_var}:${!baseline_var}"
                return 0
            fi
        fi
    done
    
    # Default fallback
    echo "STATIC_FILE:unknown::unknown"
}

# Function to get extraction directories (used by extract script)
get_extraction_dirs() {
    local dirs=()
    
    # Get all unique extracted_path values from YAML config
    local patterns=(
        "prometheus.yml@datasources"
        "prometheus.yml"
        "blackbox.yml" 
        "alertmanager.yml"
        "karma.yml"
        "grafana.ini"
        "nginx.conf"
        "ingress.conf"
        "dashboard-provider.yml"
        "*.json"
        "*.yml"
    )
    
    for pattern in "${patterns[@]}"; do
        local var_prefix="CONFIG_${pattern//[^a-zA-Z0-9]/_}"
        local extract_var="${var_prefix}_EXTRACTED_PATH"
        
        if [ -n "${!extract_var}" ]; then
            local dir="${!extract_var}"
            # Add to dirs if not already present
            if [[ ! " ${dirs[@]} " =~ " ${dir} " ]]; then
                dirs+=("$dir")
            fi
        fi
    done
    
    echo "${dirs[@]}"
}

# =============================================================================
# PATH HELPER FUNCTIONS
# =============================================================================
# These functions return the correct paths based on file type and location

# Get source path for a config file
get_source_path() {
    local filename="$1"
    local service_path="$2"
    local pattern_type="$3"
    
    case "$pattern_type" in
        "TEMPLATE_FILE")
            echo "$SOURCE_TEMPLATES/$filename"
            ;;
        "STATIC_FILE")
            echo "$SOURCE_ROOTFS/$service_path/$filename"
            ;;
        "GENERATED_FILE")
            echo ""  # No source file for generated files
            ;;
        *)
            echo "$SOURCE_ROOTFS/$service_path/$filename"
            ;;
    esac
}

# Get container runtime path for a config file
get_container_path() {
    local filename="$1"
    local service_path="$2"
    
    echo "$CONTAINER_ETC/$service_path/$filename"
}

# Get extraction source path (where to copy FROM in container)
get_extraction_source() {
    local service_path="$1"
    local filename="$2"
    
    echo "$CONTAINER_ETC/$service_path/$filename"
}

# Get extraction destination path (where to copy TO locally)
get_extraction_dest() {
    local extract_dir="$1"
    local filename="$2"
    
    echo "$EXTRACT_TEMP/$extract_dir/$filename"
}

# Function to compare a single config file using centralized patterns
compare_config_file() {
    local extracted_file="$1"
    local filename="$2"
    local service_dir="$3"  # Optional: for disambiguation
    
    # Get file configuration from YAML
    local file_config=$(get_file_pattern "$filename" "$extracted_file")
    IFS=':' read -r pattern_type runtime_path source_path extracted_path <<< "$file_config"
    
    echo "   🔍 $filename:"
    
    # Handle source comparison based on file type
    case "$pattern_type" in
        "TEMPLATE_FILE"|"STATIC_FILE")
            # Has source file - compare it
            local source_file_path=""
            if [ "$pattern_type" = "TEMPLATE_FILE" ]; then
                source_file_path="$SOURCE_TEMPLATES/$filename"
            elif [ "$pattern_type" = "STATIC_FILE" ] && [ -n "$source_path" ]; then
                source_file_path="$source_path/$filename"
            fi
            
            if [ -n "$source_file_path" ]; then
                compare_files \
                    "$source_file_path" \
                    "$extracted_file" \
                    "Source → Extracted" \
                    false \
                    false
            else
                echo "      📋 Source → Extracted: SKIPPED (no source file)"
            fi
            ;;
        "GENERATED_TRACKABLE")
            # Generated file but we want to track manual changes
            echo "      📋 Source → Extracted: SKIPPED (generated file, tracking manual changes)"
            ;;
        "GENERATED_FILE")
            # Pure generated file - skip source comparison
            echo "      📋 Source → Extracted: SKIPPED (generated file)"
            ;;
        *)
            echo "      📋 Source → Extracted: SKIPPED (unknown file type: $pattern_type)"
            ;;
    esac
    
    # Handle runtime comparison based on file type
    local container_path="$CONTAINER_ETC/$runtime_path/$filename"
    case "$pattern_type" in
        "GENERATED_TRACKABLE")
            # For trackable generated files, compare extracted vs runtime with filtering
            # Use is_generated=false to avoid the complex regeneration logic in compare_files
            # This will do simple runtime vs extracted comparison with filtering
            compare_files \
                "$container_path" \
                "$extracted_file" \
                "Runtime → Extracted (tracking manual changes)" \
                true \
                false
            ;;
        *)
            # Standard runtime comparison
            compare_files \
                "$container_path" \
                "$extracted_file" \
                "Runtime → Extracted" \
                true \
                $([ "$pattern_type" = "GENERATED_FILE" ] && echo "true" || echo "false")
            ;;
    esac
    
    echo ""
}

# Initialize YAML configuration if this script is sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    parse_config_files  # Initialize YAML configuration
fi 