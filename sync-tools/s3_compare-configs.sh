#!/usr/bin/with-contenv bashio

# =============================================================================
# INFLUXDB STACK SYNC TOOLS - CONFIGURATION COMPARISON
# =============================================================================
# PURPOSE: Compare extracted configurations with repository source files
# USAGE:   ./sync-tools/s3_compare-configs.sh
# 
# This script compares:
# 1. Extracted runtime configurations (from s2_extract-configs.sh)
# 2. Repository source files (from ./influxdb-stack/)
# 3. Identifies differences and suggests sync actions
#
# COMPARISON TYPES:
# - TEMPLATE_FILE: Compare against template files in repository root
# - STATIC_FILE: Compare against files in rootfs/etc/
# - GENERATED_TRACKABLE: Track manual changes to generated files
#
# OUTPUT: Detailed comparison report with sync recommendations
# =============================================================================

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Load environment and set defaults
load_env
set_defaults

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
        "DIFF") echo -e "\033[0;35m🔄 $message\033[0m" ;;
    esac
}

echo "🔍 InfluxDB Stack Sync Tools - Configuration Comparison"
echo "======================================================"
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

print_status "INFO" "Comparing extracted configurations with repository..."
print_status "INFO" "Extracted: $EXTRACTED_DIR"
print_status "INFO" "Source: $SOURCE_ROOT"
echo ""

# Load configuration files definition
CONFIG_FILE="$SCRIPT_DIR/config-files.yml"
if [ ! -f "$CONFIG_FILE" ]; then
    print_status "ERROR" "Configuration file not found: $CONFIG_FILE"
    exit 1
fi

# Function to compare files
compare_file() {
    local file_pattern="$1"
    local file_type="$2"
    local runtime_path="$3"
    local source_path="$4"
    local extracted_path="$5"
    local description="$6"
    
    echo "📄 Comparing: $file_pattern ($file_type)"
    echo "   Description: $description"
    
    # Find actual files matching pattern
    local extracted_files
    if [ -d "$EXTRACTED_DIR/$extracted_path" ]; then
        extracted_files=$(find "$EXTRACTED_DIR/$extracted_path" -name "$file_pattern" -type f 2>/dev/null)
    fi
    
    if [ -z "$extracted_files" ]; then
        print_status "WARN" "No extracted files found matching: $file_pattern"
        echo ""
        return
    fi
    
    while IFS= read -r extracted_file; do
        local filename=$(basename "$extracted_file")
        local source_file=""
        
        # Determine source file path based on type
        case "$file_type" in
            "TEMPLATE_FILE")
                source_file="$source_path/$filename"
                ;;
            "STATIC_FILE")
                if [ -n "$runtime_path" ]; then
                    source_file="$source_path/$runtime_path/$filename"
                else
                    # Search for file in source tree
                    source_file=$(find "$SOURCE_ROOT" -name "$filename" -type f 2>/dev/null | head -1)
                fi
                ;;
            "GENERATED_TRACKABLE")
                print_status "INFO" "Generated file (tracking changes): $filename"
                echo "     Runtime: $extracted_file"
                echo ""
                continue
                ;;
        esac
        
        # Check if source file exists
        if [ ! -f "$source_file" ]; then
            print_status "WARN" "Source file not found: $source_file"
            echo "     Runtime: $extracted_file"
            echo ""
            continue
        fi
        
        # Compare files
        if diff -q "$source_file" "$extracted_file" >/dev/null 2>&1; then
            print_status "OK" "Files match: $filename"
        else
            print_status "DIFF" "Files differ: $filename"
            echo "     Source:  $source_file"
            echo "     Runtime: $extracted_file"
            
            # Show diff preview (first 10 lines)
            echo "     Diff preview:"
            diff -u "$source_file" "$extracted_file" | head -20 | sed 's/^/       /'
            
            if [ "$(diff -u "$source_file" "$extracted_file" | wc -l)" -gt 20 ]; then
                echo "       ... (truncated, use 'diff -u' for full comparison)"
            fi
        fi
        echo ""
    done <<< "$extracted_files"
}

# Parse YAML and compare each file type
echo "🔄 Processing configuration files..."
echo ""

# Get all file patterns from YAML
file_patterns=$(yq eval 'keys | .[]' "$CONFIG_FILE")

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
    
    # Compare this file pattern
    compare_file "$pattern" "$file_type" "$runtime_path" "$source_path" "$extracted_path" "$description"
    
done <<< "$file_patterns"

# Summary
echo "📊 Comparison Summary"
echo "===================="

total_extracted=$(find "$EXTRACTED_DIR" -type f 2>/dev/null | wc -l)
total_source=$(find "$SOURCE_ROOT" -name "*.yml" -o -name "*.json" -o -name "*.conf" -o -name "*.ini" | wc -l)

echo "Files extracted: $total_extracted"
echo "Source files: $total_source"
echo ""

print_status "OK" "Configuration comparison completed"
print_status "INFO" "Next steps:"
print_status "INFO" "  • Review differences above"
print_status "INFO" "  • Run s4_sync-to-repo.sh to sync changes back to repository"
print_status "INFO" "  • Or manually update files as needed" 