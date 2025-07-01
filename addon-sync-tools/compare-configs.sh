#!/bin/bash
# compare-configs.sh - Compare extracted configuration files with git repository

# Auto-detect mode for informational purposes
if docker ps --filter 'name=prometheus-stack-test' --format '{{.Names}}' | grep -q prometheus-stack-test 2>/dev/null; then
    echo "🧪 Test mode detected (local container)"
    MODE_INFO="Test mode - comparing with local test container configs"
else
    echo "🏠 Addon mode detected (remote Home Assistant)"
    MODE_INFO="Addon mode - comparing with Home Assistant addon configs"
fi

echo "🔍 Comparing extracted configuration files with git repository..."
echo "$MODE_INFO"
echo "================================================================"

# Check if extraction has been done
if [ ! -d "./ssh-extracted-configs" ]; then
    echo "❌ No extracted files found!"
    echo "📥 Run ./extract-configs.sh first"
    exit 1
fi

echo "📊 Configuration File Comparison:"
echo ""

# Function to compare files
compare_files() {
    local git_file="$1"
    local extracted_file="$2" 
    local desc="$3"
    
    if [ -f "$git_file" ] && [ -f "$extracted_file" ]; then
        if diff -q "$git_file" "$extracted_file" > /dev/null; then
            echo "   ✅ $desc - IDENTICAL"
        else
            echo "   🔄 $desc - DIFFERENT"
            echo "      📋 Run: diff $git_file $extracted_file"
        fi
    elif [ -f "$git_file" ]; then
        echo "   ❌ $desc - NOT FOUND in extracted files"
    elif [ -f "$extracted_file" ]; then
        echo "   🆕 $desc - NEW FILE (created in addon)"
    else
        echo "   ⚠️ $desc - NOT FOUND in either location"
    fi
}

# 1. Dashboard Files Comparison
echo "🔸 Dashboard Files:"
RUNTIME_DASHBOARDS="./prometheus-stack/rootfs/etc/grafana/provisioning/dashboards"
SOURCE_DASHBOARDS="./dashboards"

if [ -d "./ssh-extracted-configs/dashboards" ]; then
    echo "   Extracted: $(find ./ssh-extracted-configs/dashboards -name "*.json" 2>/dev/null | wc -l) dashboard files"
    
    # Compare each dashboard
    for dashboard in ./ssh-extracted-configs/dashboards/dashboards/*.json; do
        if [ -f "$dashboard" ]; then
            filename=$(basename "$dashboard")
            compare_files "$SOURCE_DASHBOARDS/$filename" "$dashboard" "Dashboard: $filename"
        fi
    done
    
    # Also compare with runtime versions
    for dashboard in ./ssh-extracted-configs/dashboards/dashboards/*.json; do
        if [ -f "$dashboard" ]; then
            filename=$(basename "$dashboard")
            compare_files "$RUNTIME_DASHBOARDS/$filename" "$dashboard" "Runtime: $filename"
        fi
    done
else
    echo "   ❌ No dashboards extracted"
fi

echo ""

# 2. Prometheus Configuration Comparison
echo "🔸 Prometheus Configuration:"
RUNTIME_PROMETHEUS="./prometheus-stack/rootfs/etc/prometheus"

if [ -d "./ssh-extracted-configs/prometheus" ]; then
    echo "   Extracted: $(find ./ssh-extracted-configs/prometheus -type f 2>/dev/null | wc -l) prometheus files"
    
    # Compare prometheus.yml
    compare_files "./prometheus-stack/prometheus.yml" "./ssh-extracted-configs/prometheus/prometheus.yml" "prometheus.yml (source)"
    compare_files "$RUNTIME_PROMETHEUS/prometheus.yml" "./ssh-extracted-configs/prometheus/prometheus.yml" "prometheus.yml (runtime)"
    
    # Compare alert rules if they exist
    if [ -d "./ssh-extracted-configs/prometheus/rules" ]; then
        echo "   📋 Alert rules found in extracted files"
        for rule_file in ./ssh-extracted-configs/prometheus/rules/*.yml; do
            if [ -f "$rule_file" ]; then
                filename=$(basename "$rule_file")
                compare_files "$RUNTIME_PROMETHEUS/rules/$filename" "$rule_file" "Alert rule: $filename"
            fi
        done
    fi
else
    echo "   ❌ No prometheus config extracted"
fi

echo ""

# 3. Grafana Configuration Comparison
echo "🔸 Grafana Configuration:"
RUNTIME_GRAFANA="./prometheus-stack/rootfs/etc/grafana"

if [ -d "./ssh-extracted-configs/grafana" ]; then
    echo "   Extracted: $(find ./ssh-extracted-configs/grafana -type f 2>/dev/null | wc -l) grafana files"
    
    # Compare grafana.ini
    compare_files "./prometheus-stack/grafana.ini" "./ssh-extracted-configs/grafana/grafana.ini" "grafana.ini (source)"
    
    # Compare provisioning files
    if [ -f "./ssh-extracted-configs/grafana/provisioning/datasources/prometheus.yml" ]; then
        compare_files "$RUNTIME_GRAFANA/provisioning/datasources/prometheus.yml" "./ssh-extracted-configs/grafana/provisioning/datasources/prometheus.yml" "Datasource: prometheus.yml"
    fi
else
    echo "   ❌ No grafana config extracted"
fi

echo ""

# 4. Blackbox Exporter Configuration Comparison
echo "🔸 Blackbox Exporter Configuration:"
RUNTIME_BLACKBOX="./prometheus-stack/rootfs/etc/blackbox_exporter"

if [ -d "./ssh-extracted-configs/blackbox" ]; then
    echo "   Extracted: $(find ./ssh-extracted-configs/blackbox -type f 2>/dev/null | wc -l) blackbox files"
    
    # Compare blackbox.yml
    compare_files "./prometheus-stack/blackbox.yml" "./ssh-extracted-configs/blackbox/blackbox.yml" "blackbox.yml (source)"
    compare_files "$RUNTIME_BLACKBOX/blackbox.yml" "./ssh-extracted-configs/blackbox/blackbox.yml" "blackbox.yml (runtime)"
else
    echo "   ❌ No blackbox config extracted"
fi

echo ""

# 5. Alertmanager Configuration Comparison
echo "🔸 Alertmanager Configuration:"
RUNTIME_ALERTMANAGER="./prometheus-stack/rootfs/etc/alertmanager"

if [ -d "./ssh-extracted-configs/alerting" ]; then
    echo "   Extracted: $(find ./ssh-extracted-configs/alerting -type f 2>/dev/null | wc -l) alerting files"
    
    # Compare alertmanager.yml (note: this is dynamically generated, so differences are expected)
    if [ -f "./ssh-extracted-configs/alerting/alertmanager.yml" ]; then
        echo "   🔄 alertmanager.yml - DYNAMIC (generated from options.json)"
        echo "      📋 Generated config (differences expected):"
        echo "      📋 Run: cat ./ssh-extracted-configs/alerting/alertmanager.yml"
    fi
else
    echo "   ❌ No alerting config extracted"
fi

echo ""

# 6. Summary of New Files
echo "🔸 New Files (only in extracted, not in git):"
FOUND_NEW=false

# Check each component for new files
for component in dashboards prometheus grafana blackbox alerting; do
    if [ -d "./ssh-extracted-configs/$component" ]; then
        while IFS= read -r -d '' file; do
            filename=$(basename "$file")
            if [ "$component" = "dashboards" ]; then
                if [ ! -f "./dashboards/$filename" ] && [ ! -f "$RUNTIME_DASHBOARDS/$filename" ]; then
                    echo "   🆕 $component/$filename"
                    FOUND_NEW=true
                fi
            elif [ "$component" = "alerting" ]; then
                # Skip alertmanager.yml as it's always dynamic
                if [ "$filename" != "alertmanager.yml" ]; then
                    echo "   🆕 $component/$filename"
                    FOUND_NEW=true
                fi
            else
                # For other components, check if file exists in source
                source_file=""
                case "$component" in
                    "prometheus") source_file="./prometheus-stack/$filename" ;;
                    "grafana") source_file="./prometheus-stack/$filename" ;;
                    "blackbox") source_file="./prometheus-stack/$filename" ;;
                esac
                
                if [ -n "$source_file" ] && [ ! -f "$source_file" ]; then
                    echo "   🆕 $component/$filename"
                    FOUND_NEW=true
                fi
            fi
        done < <(find "./ssh-extracted-configs/$component" -type f -print0 2>/dev/null)
    fi
done

if [ "$FOUND_NEW" = false ]; then
    echo "   ✅ No new files found"
fi

echo ""
echo "📋 Summary & Next Steps:"
echo "================================"
echo "1. ✅ Files with IDENTICAL: No action needed"
echo "2. 🔄 Files with DIFFERENT: Review differences and decide what to sync"
echo "3. 🆕 NEW FILES: Consider adding to git repository"
echo "4. 📋 DYNAMIC configs (alertmanager.yml): Check if options.json needs updating"
echo ""
echo "💡 Workflow:"
echo "   1. Review differences: Use the 'diff' commands shown above"
echo "   2. Copy desired changes: Manually update files in git repository"
echo "   3. Update corresponding files in prometheus-stack/rootfs/etc/"
echo "   4. Test changes: Run build-test.sh to verify everything works"
echo "   5. Commit: Add changes to git when satisfied" 