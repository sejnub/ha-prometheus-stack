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
    mapfile -t dashboard_files < <(find "$extracted_dir/dashboards/dashboards" -type f -name "*.json" 2>/dev/null)
    
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
declare -i expected_changes=0    # runtime != extracted (normal workflow)
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
    local has_diff=false
    
    if [ "$is_runtime" = "true" ]; then
        # For runtime files, we need to extract them from the container first
        local temp_dir=$(mktemp -d)
        local temp_file="${temp_dir}/$(basename "$target_file")"
        
        if [ "$is_generated" = "true" ]; then
            # For generated files, compare with what would be generated from options.json
            case "$(basename "$target_file")" in
                alertmanager.yml)
                    # Get current options.json and generate alertmanager config from it
                    docker cp "${container_id}:/data/options.json" "${temp_dir}/options.json" 2>/dev/null
                    
                    # Generate alertmanager.yml from options.json (simplified version)
                    python3 -c "
import json
import yaml

with open('${temp_dir}/options.json', 'r') as f:
    options = json.load(f)

config = {
    'global': {
        'resolve_timeout': '5m'
    },
    'route': {
        'receiver': 'default'
    },
    'receivers': [
        {'name': 'default'}
    ]
}

# Add SMTP config if present
if 'smtp_host' in options and 'smtp_port' in options:
    config['global']['smtp_smarthost'] = f\"{options['smtp_host']}:{options['smtp_port']}\"
    config['global']['smtp_from'] = f\"alertmanager@{options['smtp_host']}\"

# Add email receiver if present
if 'alertmanager_receiver' in options and 'alertmanager_to_email' in options:
    config['route']['receiver'] = options['alertmanager_receiver']
    config['receivers'] = [
        {
            'name': options['alertmanager_receiver'],
            'email_configs': [
                {'to': options['alertmanager_to_email']}
            ]
        }
    ]

with open('${temp_dir}/generated_alertmanager.yml', 'w') as f:
    yaml.dump(config, f, default_flow_style=False, sort_keys=True)
" 2>/dev/null
                    
                    # Compare with generated config
                    if [ -f "${temp_dir}/generated_alertmanager.yml" ]; then
                        if diff -u <(filter_known_differences "$target_file") <(filter_known_differences "${temp_dir}/generated_alertmanager.yml") >/dev/null 2>&1; then
                            echo "      ✅ $description: Identical (after filtering placeholders)"
                        else
                            echo "      ❌ $description: Configuration differs from what would be generated from options.json"
                            echo "      📋 Differences:"
                            diff -u <(filter_known_differences "${temp_dir}/generated_alertmanager.yml") <(filter_known_differences "$target_file") | sed 's/^/         /'
                            has_diff=true
                        fi
                    else
                        echo "      ❌ $description: Could not generate config from options.json"
                        has_diff=true
                    fi
                    rm -rf "$temp_dir"
                    
                    # Update file status for runtime comparison
                    local current_status="${file_status[$filename]:-,}"
                    if [ "$has_diff" = "true" ]; then
                        file_status[$filename]="${current_status%,},runtime_diff"
                    else
                        file_status[$filename]="${current_status%,},runtime_same"
                    fi
                    return
                    ;;
                prometheus.yml|grafana.ini|blackbox.yml)
                    # These files are generated at runtime, so we can't compare them
                    echo "      ✅ $description: Generated at runtime"
                    rm -rf "$temp_dir"
                    return
                    ;;
            esac
        else
            # For normal runtime files, copy from container and compare
            local container_path="$source_file"
            
            if ! docker cp "${container_id}:$container_path" "$temp_file" 2>/dev/null; then
                echo "      ❌ $description: File not found in container"
                has_diff=true
                rm -rf "$temp_dir"
            else
                source_file="$temp_file"
            fi
        fi
    fi
    
    # For source files, check if they exist in the repository
    if [ ! -f "$source_file" ]; then
        if [ "$is_generated" = "true" ]; then
            echo "      ✅ $description: Generated at runtime"
        else
            echo "      ❌ $description: Source file missing (not in repository)"
            has_diff=true
        fi
        [ -d "$temp_dir" ] && rm -rf "$temp_dir"
        
        # Update file status
        if [ "$is_runtime" = "true" ]; then
            local current_status="${file_status[$filename]:-,}"
            if [ "$has_diff" = "true" ]; then
                file_status[$filename]="${current_status%,},runtime_diff"
            else
                file_status[$filename]="${current_status%,},runtime_same"
            fi
        else
            if [ "$has_diff" = "true" ]; then
                file_status[$filename]="source_diff,${file_status[$filename]#*,}"
            else
                file_status[$filename]="source_same,${file_status[$filename]#*,}"
            fi
        fi
        return 1
    fi
    
    # For target files, check if they exist in the extracted directory
    if [ ! -f "$target_file" ]; then
        echo "      ❌ $description: Target file missing"
        has_diff=true
        [ -d "$temp_dir" ] && rm -rf "$temp_dir"
        
        # Update file status
        if [ "$is_runtime" = "true" ]; then
            local current_status="${file_status[$filename]:-,}"
            file_status[$filename]="${current_status%,},runtime_diff"
        else
            file_status[$filename]="source_diff,${file_status[$filename]#*,}"
        fi
        return 1
    fi
    
    # Create temporary files with filtered content
    local compare_temp_dir=$(mktemp -d)
    local temp_source="${compare_temp_dir}/source"
    local temp_target="${compare_temp_dir}/target"
    
    filter_known_differences "$source_file" > "$temp_source"
    filter_known_differences "$target_file" > "$temp_target"
    
    # Compare the filtered files
    if diff -q "$temp_source" "$temp_target" >/dev/null; then
        echo "      ✅ $description: Identical (after filtering placeholders)"
    else
        echo "      ❌ $description: Files differ"
        echo "      📋 Differences:"
        diff -u "$temp_source" "$temp_target" | sed 's/^/         /'
        has_diff=true
    fi
    
    # Update file status
    if [ "$is_runtime" = "true" ]; then
        local current_status="${file_status[$filename]:-,}"
        if [ "$has_diff" = "true" ]; then
            file_status[$filename]="${current_status%,},runtime_diff"
        else
            file_status[$filename]="${current_status%,},runtime_same"
        fi
    else
        if [ "$has_diff" = "true" ]; then
            file_status[$filename]="source_diff,${file_status[$filename]#*,}"
        else
            file_status[$filename]="source_same,${file_status[$filename]#*,}"
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
            "Source → Extracted" \
            false \
            false
        compare_files \
            "/etc/grafana/provisioning/dashboards/$filename" \
            "$file" \
            "Runtime → Extracted" \
            true \
            false
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
            "Source → Extracted" \
            false \
            true
        compare_files \
            "/etc/prometheus/$filename" \
            "$file" \
            "Runtime → Extracted" \
            true \
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
                "Source → Extracted" \
                false \
                true
            compare_files \
                "/etc/grafana/$filename" \
                "$file" \
                "Runtime → Extracted" \
                true \
                true
            echo ""
        elif [[ "$filename" == "prometheus.yml" ]]; then
            echo "   🔍 Datasource: $filename:"
            compare_files \
                "./prometheus-stack/rootfs/etc/grafana/provisioning/datasources/$filename" \
                "$file" \
                "Source → Extracted" \
                false \
                false
            compare_files \
                "/etc/grafana/provisioning/datasources/$filename" \
                "$file" \
                "Runtime → Extracted" \
                true \
                false
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
            "Source → Extracted" \
            false \
            true
        compare_files \
            "/etc/blackbox_exporter/$filename" \
            "$file" \
            "Runtime → Extracted" \
            true \
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
        echo "   🔍 $filename:"
        compare_files \
            "./prometheus-stack/rootfs/etc/alertmanager/$filename" \
            "$file" \
            "Source → Extracted" \
            false \
            true
        compare_files \
            "/etc/alertmanager/$filename" \
            "$file" \
            "Runtime → Extracted" \
            true \
            true
        echo ""
    done
else
    echo "   ❌ No alerting files found in extracted configs"
fi

# Check for new files
echo -e "\n🆕 New Files (only in extracted):"
check_new_files

# Analyze file statuses and count changes
echo ""
echo "📋 Summary & Next Steps:"
echo "================================="

# Count total comparisons and analyze per-file status
total_files=0
for filename in "${!file_status[@]}"; do
    ((total_files++))
    status="${file_status[$filename]}"
    source_status="${status%,*}"
    runtime_status="${status#*,}"
    
    # Classify the overall situation for this file
    if [[ "$source_status" == "source_diff" && "$runtime_status" == "runtime_diff" ]]; then
        # Both source and runtime differ from extracted - irregular
        ((irregular_changes++))
    elif [[ "$source_status" == "source_same" && "$runtime_status" == "runtime_diff" ]]; then
        # Only runtime differs from extracted - expected workflow
        ((expected_changes++))
    elif [[ "$source_status" == "source_diff" && "$runtime_status" == "runtime_same" ]]; then
        # Only source differs from extracted - irregular
        ((irregular_changes++))
    fi
    # If both are same, no change to count
done

echo "📊 Files analyzed: $((total_files * 2)) comparisons"
echo "✅ Expected changes: $expected_changes (runtime → extracted differences - normal workflow)"
echo "⚠️  Irregular changes: $irregular_changes (unexpected differences that need attention)"

echo ""
echo "💡 Change Types:"
echo "   - Expected: Manual changes made in container, then extracted (normal workflow)"
echo "   - Irregular: Source ≠ Extracted or other unexpected differences"

echo ""
echo "💡 File Locations:"
echo "   - Extracted: Current running config (/home/sejnub/ha-proplus/./ssh-extracted-configs/...)"
echo "   - Source: Git repository files (./prometheus-stack/...)"
echo "   - Runtime: Container filesystem (./prometheus-stack/rootfs/etc/...)"

echo ""
echo "💡 Workflow:"
echo "   1. Review differences: Use the 'diff' commands shown above"
echo "   2. Update source files: Copy desired changes to source location"
echo "   3. Update runtime files: Copy to runtime location"
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