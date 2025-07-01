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

# Function definitions
find_config_files() {
    local extracted_dir="$1"
    
    # Find dashboard files
    mapfile -t dashboard_files < <(find "$extracted_dir/grafana/provisioning/dashboards" -type f -name "*.json" 2>/dev/null)
    
    # Find prometheus files
    mapfile -t prometheus_files < <(find "$extracted_dir/prometheus" -type f -name "*.yml" 2>/dev/null)
    
    # Find grafana files
    mapfile -t grafana_files < <(find "$extracted_dir/grafana" -type f \( -name "*.yml" -o -name "*.ini" \) ! -path "*/dashboards/*" 2>/dev/null)
    
    # Find blackbox files
    mapfile -t blackbox_files < <(find "$extracted_dir/blackbox" -type f -name "*.yml" 2>/dev/null)
    
    # Find alerting files
    mapfile -t alerting_files < <(find "$extracted_dir/alerting" -type f -name "*.yml" 2>/dev/null)
}

check_new_files() {
    local found_new=false
    
    # Check each component for new files
    for component in dashboards prometheus grafana blackbox alerting; do
        if [ -d "$EXTRACTED_DIR_PATH/$component" ]; then
            while IFS= read -r -d '' file; do
                relative_path=${file#"$EXTRACTED_DIR_PATH/"}
                source_path="./prometheus-stack/rootfs/etc/$relative_path"
                
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

compare_files() {
    local source_file="$1"
    local target_file="$2"
    local description="$3"
    local is_runtime="${4:-false}"
    
    if [ "$is_runtime" = "true" ]; then
        # For runtime files, we need to extract them from the container first
        local temp_dir=$(mktemp -d)
        local temp_file="${temp_dir}/$(basename "$target_file")"
        
        echo "      🔍 DEBUG: Copying from container $container_id:$source_file to $temp_file"
        if ! docker cp "${container_id}:$source_file" "$temp_file" 2>/dev/null; then
            echo "      ❌ $description: File not found in container"
            echo "      🔍 DEBUG: docker cp failed"
            rm -rf "$temp_dir" 2>/dev/null
            return 1
        fi
        echo "      🔍 DEBUG: Successfully copied file from container"
        source_file="$temp_file"
    fi

    # Check if files exist
    if [ ! -f "$source_file" ]; then
        if [ "$description" = "Source → Extracted" ]; then
            echo "      ❌ $description: Source file missing (not in repository)"
        elif [ "$description" = "Source and Runtime files" ]; then
            echo "      ❌ $description: Source file missing (not in repository)"
        else
            echo "      ❌ $description: Source file missing"
        fi
        [ "$is_runtime" = "true" ] && rm -rf "$temp_dir" 2>/dev/null
        return 1
    fi
    
    if [ ! -f "$target_file" ]; then
        if [ "$description" = "Runtime → Extracted" ]; then
            echo "      ❌ $description: Runtime file not found in container"
        else
            echo "      ❌ $description: Target file missing"
        fi
        [ "$is_runtime" = "true" ] && rm -rf "$temp_dir" 2>/dev/null
        return 1
    fi
    
    # Filter out known differences and compare
    if diff -u <(filter_known_differences "$source_file" 2>/dev/null) <(filter_known_differences "$target_file" 2>/dev/null) >/dev/null 2>&1; then
        echo "      ✅ $description: Identical (after filtering placeholders)"
        [ "$is_runtime" = "true" ] && rm -rf "$temp_dir" 2>/dev/null
        return 0
    else
        echo "      ⚠️ $description: Different"
        echo "         📋 View changes: diff \"$source_file\" \"$target_file\""
        [ "$is_runtime" = "true" ] && rm -rf "$temp_dir" 2>/dev/null
        return 1
    fi
}

filter_known_differences() {
    local file="$1"
    
    # Remove comments, empty lines, and normalize whitespace
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
}

compare_alertmanager() {
    local extracted_file="$1"
    local runtime_file="$2"
    local container_id="$3"

    # Generate a fresh alertmanager.yml from current options.json for comparison
    local temp_dir=$(mktemp -d)
    local fresh_config="${temp_dir}/alertmanager.yml"
    
    # Extract current options.json from container
    if [[ "$MODE" == "Test-Mode" ]]; then
        cp "./test-data/options.json" "${temp_dir}/options.json"
    else
        docker cp "${container_id}:/data/options.json" "${temp_dir}/options.json"
    fi

    # Generate fresh alertmanager.yml from current options
    "${SCRIPT_DIR}/generate_alertmanager_config.py" "${temp_dir}/options.json" "$fresh_config"

    if [[ ! -f "$fresh_config" ]]; then
        echo "      ❌ Failed to generate fresh alertmanager.yml from options.json"
        return 1
    fi

    # Compare extracted vs fresh generated
    if diff -u <(filter_known_differences "$fresh_config") <(filter_known_differences "$extracted_file") >/dev/null 2>&1; then
        echo "      ✅ Configuration matches what would be generated from current options.json"
        local comparison_status=0
    else
        echo "      ❌ Configuration differs from what would be generated from options.json"
        echo "      📋 Differences:"
        diff -u <(filter_known_differences "$fresh_config") <(filter_known_differences "$extracted_file") | sed 's/^/         /'
        local comparison_status=1
    fi

    # Cleanup
    rm -rf "$temp_dir"
    return $comparison_status
}

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
EXTRACTED_DIR_PATH="$(resolve_path "./$EXTRACTED_DIR")"
if [ ! -d "$EXTRACTED_DIR_PATH" ]; then
    print_status "$RED" "❌ No extracted files found!"
    print_status "$RED" "📥 Run ./s2_extract-configs.sh first"
    exit 1
fi

echo "📊 Configuration File Comparison:"
echo ""

# Initialize arrays
declare -a dashboard_files=()
declare -a prometheus_files=()
declare -a grafana_files=()
declare -a blackbox_files=()
declare -a alerting_files=()

# Find all configuration files
find_config_files "$EXTRACTED_DIR_PATH"

# Compare dashboard files
echo -e "\n🔸 Dashboard Files:"
if [ ${#dashboard_files[@]} -gt 0 ]; then
    echo "   Extracted: ${#dashboard_files[@]} dashboard files"
    for file in "${dashboard_files[@]}"; do
        filename=$(basename "$file")
        echo "   🔍 Dashboard: $filename:"
        compare_files \
            "./prometheus-stack/rootfs/etc/grafana/provisioning/dashboards/$filename" \
            "$file" \
            "Source → Extracted"
        compare_files \
            "/etc/grafana/provisioning/dashboards/$filename" \
            "$file" \
            "Runtime → Extracted" \
            true
        compare_files \
            "./prometheus-stack/rootfs/etc/grafana/provisioning/dashboards/$filename" \
            "/etc/grafana/provisioning/dashboards/$filename" \
            "Source and Runtime files" \
            true
        echo ""
    done
else
    echo "   ❌ No dashboard files found in extracted configs"
fi

# Compare prometheus configuration
echo -e "\n🔸 Prometheus Configuration:"
if [ ${#prometheus_files[@]} -gt 0 ]; then
    echo "   Extracted: ${#prometheus_files[@]} prometheus files"
    for file in "${prometheus_files[@]}"; do
        filename=$(basename "$file")
        echo "   🔍 $filename:"
        compare_files \
            "./prometheus-stack/rootfs/etc/prometheus/$filename" \
            "$file" \
            "Source → Extracted"
        compare_files \
            "/etc/prometheus/$filename" \
            "$file" \
            "Runtime → Extracted" \
            true
        compare_files \
            "./prometheus-stack/rootfs/etc/prometheus/$filename" \
            "/etc/prometheus/$filename" \
            "Source and Runtime files" \
            true
        echo ""
    done
else
    echo "   ❌ No prometheus files found in extracted configs"
fi

# Compare grafana configuration
echo -e "\n🔸 Grafana Configuration:"
if [ ${#grafana_files[@]} -gt 0 ]; then
    echo "   Extracted: ${#grafana_files[@]} grafana files"
    for file in "${grafana_files[@]}"; do
        filename=$(basename "$file")
        if [[ "$filename" == "grafana.ini" ]]; then
            echo "   🔍 $filename:"
            compare_files \
                "./prometheus-stack/rootfs/etc/grafana/$filename" \
                "$file" \
                "Source → Extracted"
            compare_files \
                "/etc/grafana/$filename" \
                "$file" \
                "Runtime → Extracted" \
                true
            compare_files \
                "./prometheus-stack/rootfs/etc/grafana/$filename" \
                "/etc/grafana/$filename" \
                "Source and Runtime files" \
                true
            echo ""
        elif [[ "$filename" == "prometheus.yml" ]]; then
            echo "   🔍 Datasource: $filename:"
            compare_files \
                "./prometheus-stack/rootfs/etc/grafana/provisioning/datasources/$filename" \
                "$file" \
                "Source → Extracted"
            compare_files \
                "/etc/grafana/provisioning/datasources/$filename" \
                "$file" \
                "Runtime → Extracted" \
                true
            compare_files \
                "./prometheus-stack/rootfs/etc/grafana/provisioning/datasources/$filename" \
                "/etc/grafana/provisioning/datasources/$filename" \
                "Source and Runtime files" \
                true
            echo ""
        fi
    done
else
    echo "   ❌ No grafana files found in extracted configs"
fi

# Compare blackbox configuration
echo -e "\n🔸 Blackbox Exporter Configuration:"
if [ ${#blackbox_files[@]} -gt 0 ]; then
    echo "   Extracted: ${#blackbox_files[@]} blackbox files"
    for file in "${blackbox_files[@]}"; do
        filename=$(basename "$file")
        echo "   🔍 $filename:"
        compare_files \
            "./prometheus-stack/rootfs/etc/blackbox_exporter/$filename" \
            "$file" \
            "Source → Extracted"
        compare_files \
            "/etc/blackbox_exporter/$filename" \
            "$file" \
            "Runtime → Extracted" \
            true
        compare_files \
            "./prometheus-stack/rootfs/etc/blackbox_exporter/$filename" \
            "/etc/blackbox_exporter/$filename" \
            "Source and Runtime files" \
            true
        echo ""
    done
else
    echo "   ❌ No blackbox files found in extracted configs"
fi

# Compare alertmanager configuration
echo -e "\n🔸 Alertmanager Configuration:"
if [ ${#alerting_files[@]} -gt 0 ]; then
    echo "   Extracted: ${#alerting_files[@]} alerting files"
    for file in "${alerting_files[@]}"; do
        filename=$(basename "$file")
        if [[ "$filename" == "alertmanager.yml" ]]; then
            echo "   🔍 $filename (from container):"
            compare_alertmanager "$file" "$RUNTIME_DIR/alertmanager/$filename" "$container_id"
        fi
    done
else
    echo "   ❌ No alertmanager files found in extracted configs"
fi

# Check for new files
echo -e "\n🔸 New Files (only in extracted):"
check_new_files

echo ""
echo "📋 Summary & Next Steps:"
echo "================================"
echo "1. ✅ Identical files: No action needed"
echo "2. ⚠️ Different files: Review changes using the diff commands shown above"
echo "3. 🆕 New files: Consider adding to source and runtime locations"
echo "4. 🔄 Dynamic configs (alertmanager.yml): Generated from options.json"
echo ""
echo "💡 File Locations:"
echo "   - Extracted: Current running config ($EXTRACTED_DIR_PATH/...)"
echo "   - Source: Git repository files (./prometheus-stack/...)"
echo "   - Runtime: Container filesystem (./prometheus-stack/rootfs/etc/...)"
echo ""
echo "💡 Workflow:"
echo "   1. Review differences: Use the 'diff' commands shown above"
echo "   2. Update source files: Copy desired changes to source location"
echo "   3. Update runtime files: Copy to runtime location"
echo "   4. Test changes: Run build.sh to verify everything works"
echo "   5. Commit: Add changes to git when satisfied"

# Check if comparison was successful and provide summary
if [ -d "./$EXTRACTED_DIR" ] && [ "$(find ./$EXTRACTED_DIR -type f 2>/dev/null | wc -l)" -gt 0 ]; then
    print_status_icon "OK" "Configuration comparison completed successfully - Review differences above"
else
    print_status_icon "ERROR" "Configuration comparison failed - No extracted files found"
    exit 1
fi 