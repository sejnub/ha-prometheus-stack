#!/usr/bin/with-contenv bashio

# =============================================================================
# INFLUXDB STACK SYNC TOOLS - REPOSITORY SYNCHRONIZATION
# =============================================================================
# PURPOSE: Sync extracted configurations back to repository
# USAGE:   ./sync-tools/s4_sync-to-repo.sh [--dry-run]
# 
# This script:
# 1. Compares extracted runtime configurations with repository files
# 2. Identifies files that need to be updated
# 3. Creates backups of existing files
# 4. Copies updated configurations to repository
# 5. Provides git commit suggestions
#
# SYNC TYPES:
# - TEMPLATE_FILE: Sync to repository root (e.g., grafana.ini)
# - STATIC_FILE: Sync to rootfs/etc/ structure
# - GENERATED_TRACKABLE: Track changes but don't auto-sync
#
# OPTIONS:
#   --dry-run: Show what would be synced without making changes
# =============================================================================

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Load environment and set defaults
load_env
set_defaults

# Parse command line arguments
DRY_RUN_FLAG="$DRY_RUN"
if [ "$1" = "--dry-run" ]; then
    DRY_RUN_FLAG="true"
fi

# Load YAML configuration
if ! command -v yq >/dev/null 2>&1; then
    echo "❌ Error: yq is required but not installed."
    echo "Install with: sudo apt-get install yq"
    exit 1
fi

print_status() {
    local status="$1"
    local message="$2"
    case $status in
        "OK") echo -e "\033[0;32m✅ $message\033[0m" ;;
        "WARN") echo -e "\033[1;33m⚠️  $message\033[0m" ;;
        "ERROR") echo -e "\033[0;31m❌ $message\033[0m" ;;
        "INFO") echo -e "\033[0;34mℹ️  $message\033[0m" ;;
        "SYNC") echo -e "\033[0;35m🔄 $message\033[0m" ;;
        "SKIP") echo -e "\033[0;37m⏭️  $message\033[0m" ;;
    esac
}

echo "🔄 InfluxDB Stack Sync Tools - Repository Synchronization"
echo "========================================================"
if [ "$DRY_RUN_FLAG" = "true" ]; then
    echo "🧪 DRY RUN MODE - No changes will be made"
fi
echo ""

# Check if extraction directory exists
if [ ! -d "$EXTRACTED_DIR" ]; then
    print_status "ERROR" "Extracted configurations not found at: $EXTRACTED_DIR"
    print_status "INFO" "Run s2_extract-configs.sh first to extract configurations"
    exit 1
fi

# Check if repository exists
if [ ! -d "$SOURCE_ROOT" ]; then
    print_status "ERROR" "Source repository not found at: $SOURCE_ROOT"
    exit 1
fi

print_status "INFO" "Syncing extracted configurations to repository..."
print_status "INFO" "Extracted: $EXTRACTED_DIR"
print_status "INFO" "Target: $SOURCE_ROOT"
echo ""

# Create backup directory
BACKUP_DIR="$SYNC_BACKUP_DIR/$(date +%Y%m%d_%H%M%S)"
if [ "$DRY_RUN_FLAG" != "true" ]; then
    mkdir -p "$BACKUP_DIR"
    print_status "INFO" "Backup directory: $BACKUP_DIR"
fi

# Load configuration files definition
CONFIG_FILE="$SCRIPT_DIR/config-files.yml"
if [ ! -f "$CONFIG_FILE" ]; then
    print_status "ERROR" "Configuration file not found: $CONFIG_FILE"
    exit 1
fi

# Counters for summary
sync_count=0
skip_count=0
error_count=0

# Function to sync files
sync_file() {
    local file_pattern="$1"
    local file_type="$2"
    local runtime_path="$3"
    local source_path="$4"
    local extracted_path="$5"
    local description="$6"
    
    echo "📄 Processing: $file_pattern ($file_type)"
    
    # Find actual files matching pattern
    local extracted_files
    if [ -d "$EXTRACTED_DIR/$extracted_path" ]; then
        extracted_files=$(find "$EXTRACTED_DIR/$extracted_path" -name "$file_pattern" -type f 2>/dev/null)
    fi
    
    if [ -z "$extracted_files" ]; then
        print_status "SKIP" "No extracted files found matching: $file_pattern"
        ((skip_count++))
        echo ""
        return
    fi
    
    while IFS= read -r extracted_file; do
        local filename=$(basename "$extracted_file")
        local target_file=""
        
        # Determine target file path based on type
        case "$file_type" in
            "TEMPLATE_FILE")
                target_file="$source_path/$filename"
                ;;
            "STATIC_FILE")
                if [ -n "$runtime_path" ]; then
                    target_file="$source_path/$runtime_path/$filename"
                else
                    # Search for existing file in source tree
                    local existing_file=$(find "$SOURCE_ROOT" -name "$filename" -type f 2>/dev/null | head -1)
                    if [ -n "$existing_file" ]; then
                        target_file="$existing_file"
                    else
                        print_status "WARN" "Cannot determine target location for: $filename"
                        ((error_count++))
                        continue
                    fi
                fi
                ;;
            "GENERATED_TRACKABLE")
                print_status "SKIP" "Generated file (not synced): $filename"
                ((skip_count++))
                continue
                ;;
        esac
        
        # Check if files are different
        if [ -f "$target_file" ] && diff -q "$target_file" "$extracted_file" >/dev/null 2>&1; then
            print_status "SKIP" "Files identical: $filename"
            ((skip_count++))
            echo ""
            continue
        fi
        
        # Create target directory if it doesn't exist
        local target_dir=$(dirname "$target_file")
        if [ ! -d "$target_dir" ]; then
            if [ "$DRY_RUN_FLAG" = "true" ]; then
                print_status "INFO" "Would create directory: $target_dir"
            else
                mkdir -p "$target_dir"
                print_status "INFO" "Created directory: $target_dir"
            fi
        fi
        
        # Backup existing file if it exists
        if [ -f "$target_file" ] && [ "$DRY_RUN_FLAG" != "true" ]; then
            local backup_file="$BACKUP_DIR/$(basename "$target_file").backup"
            cp "$target_file" "$backup_file"
            print_status "INFO" "Backed up: $target_file → $backup_file"
        fi
        
        # Sync the file
        if [ "$DRY_RUN_FLAG" = "true" ]; then
            print_status "SYNC" "Would sync: $filename"
            echo "     From: $extracted_file"
            echo "     To:   $target_file"
        else
            cp "$extracted_file" "$target_file"
            print_status "SYNC" "Synced: $filename"
            echo "     From: $extracted_file"
            echo "     To:   $target_file"
        fi
        
        ((sync_count++))
        echo ""
        
    done <<< "$extracted_files"
}

# Parse YAML and sync each file type
echo "🔄 Processing configuration files..."
echo ""

# Get all file patterns from YAML, sorted by priority
file_patterns=$(yq eval 'to_entries | sort_by(.value.priority // 5) | .[].key' "$CONFIG_FILE")

while IFS= read -r pattern; do
    # Skip empty patterns
    [ -z "$pattern" ] && continue
    
    # Get file configuration
    file_type=$(yq eval ".\"$pattern\".type" "$CONFIG_FILE")
    runtime_path=$(yq eval ".\"$pattern\".runtime_path" "$CONFIG_FILE")
    source_path=$(yq eval ".\"$pattern\".source_path" "$CONFIG_FILE")
    extracted_path=$(yq eval ".\"$pattern\".extracted_path" "$CONFIG_FILE")
    description=$(yq eval ".\"$pattern\".description" "$CONFIG_FILE")
    
    # Skip if values are null
    if [ "$file_type" = "null" ]; then
        continue
    fi
    
    # Sync this file pattern
    sync_file "$pattern" "$file_type" "$runtime_path" "$source_path" "$extracted_path" "$description"
    
done <<< "$file_patterns"

# Summary
echo "📊 Synchronization Summary"
echo "========================="
echo "Files synced: $sync_count"
echo "Files skipped: $skip_count"
echo "Errors: $error_count"
echo ""

if [ "$DRY_RUN_FLAG" = "true" ]; then
    print_status "INFO" "Dry run completed - no changes were made"
    print_status "INFO" "Run without --dry-run to apply changes"
else
    if [ $sync_count -gt 0 ]; then
        print_status "OK" "Synchronization completed successfully"
        print_status "INFO" "Backup created: $BACKUP_DIR"
        
        # Git suggestions
        echo ""
        print_status "INFO" "Suggested git commands:"
        echo "  git add ."
        echo "  git status"
        echo "  git commit -m 'Sync InfluxDB Stack configurations from runtime'"
        echo "  git push"
    else
        print_status "INFO" "No files needed synchronization"
    fi
fi

if [ $error_count -gt 0 ]; then
    print_status "WARN" "Some files had errors during synchronization"
    exit 1
fi 