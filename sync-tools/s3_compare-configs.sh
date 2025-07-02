#!/bin/bash
# compare-configs.sh - Compare extracted configuration files with git repository

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Function to resolve paths relative to project root
resolve_path() {
    local path="$1"
    # If path starts with ./, resolve it relative to project root
    if [[ "$path" == ./* ]]; then
        echo "$PROJECT_ROOT/${path#./}"
    else
        echo "$path"
    fi
}

# Source configuration
source "$SCRIPT_DIR/config.sh"

# Declare global arrays for file tracking
declare -A file_status
declare -a dashboard_files=()
declare -a prometheus_files=()
declare -a grafana_files=()
declare -a blackbox_files=()
declare -a alerting_files=()
declare -a karma_files=()
declare -a nginx_files=()

# Function definitions
find_config_files() {
    local extracted_dir="$1"
    
    # Get extraction directories from centralized config and find files
    local extraction_dirs=($(get_extraction_dirs))
    
    for dir in "${extraction_dirs[@]}"; do
        local dir_path="$extracted_dir/$dir"
        if [ -d "$dir_path" ]; then
            # Find all config files in this directory
            local files=()
            mapfile -t files < <(find "$dir_path" -type f \( -name "*.yml" -o -name "*.yaml" -o -name "*.ini" -o -name "*.json" -o -name "*.conf" \) 2>/dev/null)
            
            # Store files in appropriate arrays for compatibility
            case "$dir" in
                "dashboards") dashboard_files=("${files[@]}") ;;
                "prometheus") prometheus_files=("${files[@]}") ;;
                "grafana") grafana_files=("${files[@]}") ;;
                "blackbox") blackbox_files=("${files[@]}") ;;
                "alerting") alerting_files=("${files[@]}") ;;
                "karma") karma_files=("${files[@]}") ;;
                "nginx") nginx_files=("${files[@]}") ;;
            esac
        fi
    done
}

# compare_config_file function is now defined in config.sh

check_new_files() {
    local found_new=false
    
    # Check for dashboard files in grafana/provisioning/dashboards/
    if [ -d "$EXTRACTED_DIR_PATH/grafana/provisioning/dashboards" ]; then
        while IFS= read -r -d '' file; do
            filename=$(basename "$file")
            source_path="./prometheus-stack/rootfs/etc/grafana/provisioning/dashboards/$filename"
            
            if [ ! -f "$source_path" ]; then
                relative_path=${file#"$EXTRACTED_DIR_PATH/"}
                echo "   📝 New file: $relative_path"
                found_new=true
            fi
        done < <(find "$EXTRACTED_DIR_PATH/grafana/provisioning/dashboards" -type f -name "*.json" -print0 2>/dev/null)
    fi
    
    # Check for other grafana files
    if [ -d "$EXTRACTED_DIR_PATH/grafana" ]; then
        while IFS= read -r -d '' file; do
            relative_path=${file#"$EXTRACTED_DIR_PATH/"}
            
            # Skip dashboard files (already handled above)
            if [[ "$relative_path" == grafana/provisioning/dashboards/* ]]; then
                continue
            fi
            
            # Skip runtime-generated files
            if [[ "$relative_path" == "grafana/grafana.ini" ]]; then
                continue
            fi
            
            filename=$(basename "$file")
            if [[ "$file" == */provisioning/datasources/* ]]; then
                source_path="./prometheus-stack/rootfs/etc/grafana/provisioning/datasources/$filename"
            else
                source_path="./prometheus-stack/rootfs/etc/grafana/$filename"
            fi
            
            if [ ! -f "$source_path" ]; then
                echo "   📝 New file: $relative_path"
                found_new=true
            fi
        done < <(find "$EXTRACTED_DIR_PATH/grafana" -type f \( -name "*.yml" -o -name "*.ini" \) -print0 2>/dev/null)
    fi
    
    # Check other components
    for component in prometheus blackbox alerting; do
        if [ -d "$EXTRACTED_DIR_PATH/$component" ]; then
            while IFS= read -r -d '' file; do
                relative_path=${file#"$EXTRACTED_DIR_PATH/"}
                
                # Skip runtime-generated files
                if [[ "$relative_path" == "prometheus/prometheus.yml" ]] || \
                   [[ "$relative_path" == "blackbox/blackbox.yml" ]] || \
                   [[ "$relative_path" == "alerting/alertmanager.yml" ]]; then
                    continue
                fi
                
                # Map the extracted path to the source path
                case "$component" in
                    prometheus)
                        source_path="./prometheus-stack/rootfs/etc/prometheus/$(basename "$file")"
                        ;;
                    blackbox)
                        source_path="./prometheus-stack/rootfs/etc/blackbox_exporter/$(basename "$file")"
                        ;;
                    alerting)
                        source_path="./prometheus-stack/rootfs/etc/alertmanager/$(basename "$file")"
                        ;;
                esac
                
                if [ ! -f "$source_path" ]; then
                    echo "   📝 New file: $relative_path"
                    found_new=true
                fi
            done < <(find "$EXTRACTED_DIR_PATH/$component" -type f -print0 2>/dev/null)
        fi
    done
    
    if [ "$found_new" = false ]; then
        echo "   ✅ No new files found"
    fi
}

# Initialize counters for different types of changes
declare -i expected_changes=0    # runtime == extracted != source (normal workflow)
declare -i irregular_changes=0   # any other differences
declare -i total_files=0
declare -A file_status  # Track status per file: filename -> "source_diff,runtime_diff"

compare_files() {
    local source_file="$1"
    local target_file="$2"
    local description="$3"
    local is_runtime="${4:-false}"
    local is_generated="${5:-false}"
    
    local filename=$(basename "$target_file")
    local file_key="$target_file"  # Use full path as key to avoid conflicts
    local has_diff=false
    
    if [ "$is_runtime" = "true" ]; then
        # For runtime files, we need to extract them from the container first
        local temp_dir=$(mktemp -d)
        local temp_file="${temp_dir}/$(basename "$target_file")"
        
        # For normal runtime files, copy from container and compare
        local container_path="$source_file"
        
        if ! docker cp "${container_id}:$container_path" "$temp_file" 2>/dev/null; then
            echo "      ❌ $description: File not found in container"
            has_diff=true
            rm -rf "$temp_dir"
            
            # Update file status for runtime comparison
            local current_status="${file_status[$file_key]:-,}"
            file_status[$file_key]="${current_status%,},runtime_diff"
            return
        else
            source_file="$temp_file"
        fi
    fi
    
    # For source files, check if they exist in the repository
    if [ ! -f "$source_file" ]; then
        echo "      ❌ $description: Source file missing (not in repository)"
        has_diff=true
        
        # Update file status for source comparison
        if [ "$is_runtime" = "false" ]; then
            file_status[$file_key]="source_diff,${file_status[$file_key]#*,}"
        else
            local current_status="${file_status[$file_key]:-,}"
            file_status[$file_key]="${current_status%,},runtime_diff"
        fi
        return
    fi
    
    # Compare files using filtering
    local compare_temp_dir=$(mktemp -d)
    local temp_source="${compare_temp_dir}/source"
    local temp_target="${compare_temp_dir}/target"
    
    filter_known_differences "$source_file" > "$temp_source"
    filter_known_differences "$target_file" > "$temp_target"
    
    if diff -u "$temp_source" "$temp_target" >/dev/null 2>&1; then
        echo "      ✅ $description: Identical (after filtering placeholders)"
    else
        echo "      ❌ $description: Files differ"
        echo "      📋 Differences:"
        diff -u "$temp_source" "$temp_target" | sed 's/^/         /'
        has_diff=true
    fi
    
    # Update file status
    if [ "$is_runtime" = "true" ]; then
        local current_status="${file_status[$file_key]:-,}"
        if [ "$has_diff" = "true" ]; then
            file_status[$file_key]="${current_status%,},runtime_diff"
        else
            file_status[$file_key]="${current_status%,},runtime_same"
        fi
    else
        if [ "$has_diff" = "true" ]; then
            file_status[$file_key]="source_diff,${file_status[$file_key]#*,}"
        else
            file_status[$file_key]="source_same,${file_status[$file_key]#*,}"
        fi
    fi
    
    # Cleanup
    rm -rf "$compare_temp_dir"
    [ -d "$temp_dir" ] && rm -rf "$temp_dir"
}

filter_known_differences() {
    local file="$1"
    
    # Check if it's a YAML file
    if [[ "$file" == *.yml ]] || [[ "$file" == *.yaml ]]; then
        # For YAML files, normalize the format using Python
        python3 -c "
import yaml
import sys

try:
    with open('$file', 'r') as f:
        data = yaml.safe_load(f)
    
    # Output normalized YAML
    print(yaml.dump(data, default_flow_style=False))
except Exception as e:
    # If YAML parsing fails, fall back to text processing
    with open('$file', 'r') as f:
        content = f.read()
    
    # Remove comments, empty lines, and normalize whitespace
    lines = []
    for line in content.split('\n'):
        line = line.split('#')[0].strip()  # Remove comments
        if line:  # Skip empty lines
            lines.append(line)
    
    print('\n'.join(lines))
" 2>/dev/null || cat "$file"
    elif [[ "$file" == *.ini ]]; then
        # For INI files, normalize whitespace and empty lines
        sed 's/#.*//;s/[[:space:]]*$//;/^[[:space:]]*$/d' "$file" | \
        # Remove environment variable placeholders
        sed 's/${[^}]*}/ENV_VAR/g' | \
        # Remove version numbers
        sed 's/version: [0-9.]\+/version: X.Y.Z/g' | \
        # Remove timestamps
        sed 's/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}T[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}Z/TIMESTAMP/g' | \
        # Remove UUIDs
        sed 's/[a-f0-9]\{8\}-[a-f0-9]\{4\}-[a-f0-9]\{4\}-[a-f0-9]\{4\}-[a-f0-9]\{12\}/UUID/g' | \
        # Remove line endings
        tr -d '\r'
    else
        # For non-YAML files, use the original text processing
        sed 's/#.*//;/^[[:space:]]*$/d' "$file" | \
        # Remove environment variable placeholders
        sed 's/${[^}]*}/ENV_VAR/g' | \
        # Remove version numbers
        sed 's/version: [0-9.]\+/version: X.Y.Z/g' | \
        # Remove timestamps
        sed 's/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}T[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}Z/TIMESTAMP/g' | \
        # Remove UUIDs
        sed 's/[a-f0-9]\{8\}-[a-f0-9]\{4\}-[a-f0-9]\{4\}-[a-f0-9]\{4\}-[a-f0-9]\{12\}/UUID/g' | \
        # Remove line endings
        tr -d '\r'
    fi
}

# compare_alertmanager function removed - all logic now centralized in YAML configuration

# Load configuration and detect mode
load_env
set_defaults
MODE=$(detect_mode)

if [ "$MODE" = "test" ]; then
    echo "🧪 Test-Mode detected (local container)"
    MODE_INFO="Test-Mode - comparing with local test container configs"
    HA_IP="localhost"
    CONTAINER_FILTER="$LOCAL_CONTAINER_NAME"
    CMD_PREFIX=""
    container_id=$(docker ps -qf "name=^${LOCAL_CONTAINER_NAME}$")
    if [ -z "$container_id" ]; then
        echo "❌ Container $LOCAL_CONTAINER_NAME not found"
        exit 1
    fi
else
    echo "🏠 Addon-Mode detected (remote Home Assistant)"
    MODE_INFO="Addon-Mode - comparing with remote Home Assistant addon configs"
    HA_IP="$HA_HOSTNAME"
    CONTAINER_FILTER="$REMOTE_CONTAINER_NAME"
    CMD_PREFIX=$(get_ssh_prefix "addon")
    container_id=$(docker ps -qf "name=^${REMOTE_CONTAINER_NAME}$")
    if [ -z "$container_id" ]; then
        echo "❌ Container $REMOTE_CONTAINER_NAME not found"
        exit 1
    fi
fi

# Show configuration
show_config "$MODE"

echo "🔍 Comparing extracted configuration files with git repository..."
echo "$MODE_INFO"
echo "================================================================"

# Check if extraction has been done
EXTRACTED_DIR_PATH="$EXTRACTED_DIR"
if [ ! -d "$EXTRACTED_DIR_PATH" ]; then
    print_status "$RED" "❌ Extracted directory not found: $EXTRACTED_DIR_PATH"
    exit 1
fi

echo "📊 Configuration File Comparison:"
echo ""

# Find all configuration files
find_config_files "$EXTRACTED_DIR_PATH"

# Compare all configuration files using centralized patterns
echo -e "\n🔸 Configuration File Comparison:"
echo "Using centralized file patterns from config.sh"
echo "=============================================="

# Process each extracted directory and find all config files
total_files_found=0

# Dashboard files (special case - nested in dashboards/dashboards/)
echo -e "\n🔸 Dashboard Files:"
dashboard_dir="$EXTRACTED_DIR_PATH/dashboards"
if [ -d "$dashboard_dir" ]; then
    # Find all JSON files in the dashboards directory structure
    files=()
    mapfile -t files < <(find "$dashboard_dir" -type f -name "*.json" 2>/dev/null)
    mapfile -t -O ${#files[@]} files < <(find "$dashboard_dir" -type f -name "*.yml" 2>/dev/null)
    
    if [ ${#files[@]} -gt 0 ]; then
        echo "   Extracted: ${#files[@]} files"
        total_files_found=$((total_files_found + ${#files[@]}))
        
        for file in "${files[@]}"; do
            filename=$(basename "$file")
            compare_config_file "$file" "$filename" "dashboards"
        done
    else
        echo "   ❌ No dashboard files found"
    fi
else
    echo "   ❌ Extracted dashboards directory not found"
fi

# Process other config directories
for dir in prometheus grafana blackbox alerting karma nginx; do
    dir_path="$EXTRACTED_DIR_PATH/$dir"
    
    # Map directory to service name for display
    case "$dir" in
        "prometheus") service_name="Prometheus Configuration" ;;
        "grafana") service_name="Grafana Configuration" ;;
        "blackbox") service_name="Blackbox Exporter Configuration" ;;
        "alerting") service_name="Alertmanager Configuration" ;;
        "karma") service_name="Karma Configuration" ;;
        "nginx") service_name="NGINX Configuration" ;;
        *) service_name="$(echo ${dir^}) Configuration" ;;
    esac
    
    echo -e "\n🔸 $service_name:"
    
    if [ -d "$dir_path" ]; then
        # Find all config files in this directory
        files=()
        mapfile -t files < <(find "$dir_path" -type f \( -name "*.yml" -o -name "*.yaml" -o -name "*.ini" -o -name "*.json" -o -name "*.conf" \) 2>/dev/null)
        
        if [ ${#files[@]} -gt 0 ]; then
            echo "   Extracted: ${#files[@]} files"
            total_files_found=$((total_files_found + ${#files[@]}))
            
            for file in "${files[@]}"; do
                filename=$(basename "$file")
                compare_config_file "$file" "$filename" "$dir"
            done
        else
            echo "   ❌ No config files found in extracted $dir directory"
        fi
    else
        echo "   ❌ Extracted $dir directory not found"
    fi
done

echo -e "\n📊 Total files processed: $total_files_found"

# Check for new files
echo -e "\n🆕 New Files (only in extracted):"
check_new_files

# Analyze file statuses and count changes
echo ""
echo "📋 Summary & Next Steps:"
echo "================================="

# Count total comparisons and analyze per-file status
total_files=0

# Ensure GENERATED_TRACKABLE files have proper source status for change counting
for file_key in "${!file_status[@]}"; do
    status="${file_status[$file_key]}"
    source_status="${status%,*}"
    runtime_status="${status#*,}"
    
    # If source status is empty (from skipped source comparison), set it based on file type
    if [ -z "$source_status" ]; then
        filename=$(basename "$file_key")
        file_config=$(get_file_pattern "$filename" "$file_key")
        IFS=':' read -r pattern_type runtime_path source_path extracted_path <<< "$file_config"
        
        if [ "$pattern_type" = "GENERATED_TRACKABLE" ]; then
            # For generated trackable files, source is always "different" since no source exists
            file_status[$file_key]="source_diff,$runtime_status"
        else
            # For other files with missing source status, mark as source_same
            file_status[$file_key]="source_same,$runtime_status"
        fi
    fi
done

for file_key in "${!file_status[@]}"; do
    ((total_files++))
    status="${file_status[$file_key]}"
    source_status="${status%,*}"
    runtime_status="${status#*,}"
    
    # Classify the overall situation for this file
    if [[ "$source_status" == "source_diff" && "$runtime_status" == "runtime_diff" ]]; then
        # Both source and runtime differ from extracted - irregular
        ((irregular_changes++))
    elif [[ "$source_status" == "source_diff" && "$runtime_status" == "runtime_same" ]]; then
        # Manual changes made in runtime, then extracted - expected workflow
        ((expected_changes++))
    elif [[ "$source_status" == "source_same" && "$runtime_status" == "runtime_diff" ]]; then
        # Source matches extracted but runtime differs - irregular
        ((irregular_changes++))
    fi
    # If both are same, no change to count
done

echo "📊 Files analyzed: $((total_files * 2)) comparisons"
echo "✅ Expected changes: $expected_changes (runtime == extracted != source - normal workflow)"
echo "⚠️  Irregular changes: $irregular_changes (unexpected differences that need attention)"

echo ""
echo "💡 Change Types:"
echo "   - Expected: Manual changes made in runtime container, then extracted (runtime == extracted != source)"
echo "   - Irregular: Source ≠ Extracted, Runtime ≠ Extracted, or other unexpected differences"

echo ""
echo "💡 File Locations:"
echo "   - Extracted: Current running config (/home/sejnub/ha-proplus/./ssh-extracted-configs/...)"
echo "   - Source: Git repository files (./prometheus-stack/...)"
echo "   - Runtime: Container filesystem (./prometheus-stack/rootfs/etc/...)"

echo ""
echo "💡 Workflow:"
echo "   1. Review differences: Use the 'diff' commands shown above"
echo "   2. For expected changes (runtime == extracted != source):"
echo "      - Update source files: Copy extracted config to source location"
echo "   3. For irregular changes:"
echo "      - Decide whether to keep runtime changes or revert to source"
echo "      - Update accordingly: source → runtime or runtime → source"
echo "   4. Test changes: Run build.sh to verify everything works"
echo "   5. Commit: Add changes to git when satisfied"

if [ $expected_changes -eq 0 ] && [ $irregular_changes -eq 0 ]; then
    print_status_icon "OK" "No changes detected - all configurations are in sync"
elif [ $irregular_changes -eq 0 ]; then
    if [ $expected_changes -eq 1 ]; then
        print_status_icon "INFO" "$expected_changes expected change detected - review and sync as needed"
    else
        print_status_icon "INFO" "$expected_changes expected changes detected - review and sync as needed"
    fi
else
    if [ $irregular_changes -eq 1 ] && [ $expected_changes -eq 1 ]; then
        print_status_icon "WARNING" "$irregular_changes irregular change detected (and $expected_changes expected change) - manual review required"
    elif [ $irregular_changes -eq 1 ]; then
        print_status_icon "WARNING" "$irregular_changes irregular change detected (and $expected_changes expected changes) - manual review required"
    elif [ $expected_changes -eq 1 ]; then
        print_status_icon "WARNING" "$irregular_changes irregular changes detected (and $expected_changes expected change) - manual review required"
    else
        print_status_icon "WARNING" "$irregular_changes irregular changes detected (and $expected_changes expected changes) - manual review required"
    fi
    echo ""
    if [ $irregular_changes -eq 1 ]; then
        print_status "$RED" "🚨 $irregular_changes irregular change detected!"
        print_status "$RED" "   This change is unexpected and requires manual review."
    else
        print_status "$RED" "🚨 $irregular_changes irregular changes detected!"
        print_status "$RED" "   These changes are unexpected and require manual review."
    fi
    print_status "$RED" "   Please examine the differences shown above and take appropriate action."
fi 