#!/bin/bash
# compare-configs.sh - Compare extracted configuration files with git repository

echo "🔍 Comparing extracted configuration files with git repository..."
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
    
    # Compare with runtime dashboards
    if [ -d "$RUNTIME_DASHBOARDS" ]; then
        echo ""
        echo "   📋 Runtime dashboard comparison:"
        for file in $RUNTIME_DASHBOARDS/*.json; do
            if [ -f "$file" ]; then
                filename=$(basename "$file")
                extracted_file="./ssh-extracted-configs/dashboards/$filename"
                compare_files "$file" "$extracted_file" "$filename"
            fi
        done
    fi
    
    # Compare with source dashboards
    if [ -d "$SOURCE_DASHBOARDS" ]; then
        echo ""
        echo "   📋 Source dashboard comparison:"
        for file in $SOURCE_DASHBOARDS/*.json; do
            if [ -f "$file" ]; then
                filename=$(basename "$file")
                extracted_file="./ssh-extracted-configs/dashboards/$filename"
                compare_files "$file" "$extracted_file" "$filename"
            fi
        done
    fi
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
    compare_files "$RUNTIME_PROMETHEUS/prometheus.yml" "./ssh-extracted-configs/prometheus/prometheus.yml" "prometheus.yml"
    
    # Compare alert rules if they exist
    if [ -d "$RUNTIME_PROMETHEUS/rules" ] && [ -d "./ssh-extracted-configs/prometheus/rules" ]; then
        echo ""
        echo "   📋 Alert rules comparison:"
        for file in $RUNTIME_PROMETHEUS/rules/*; do
            if [ -f "$file" ]; then
                filename=$(basename "$file")
                extracted_file="./ssh-extracted-configs/prometheus/rules/$filename"
                compare_files "$file" "$extracted_file" "rules/$filename"
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
    compare_files "$RUNTIME_GRAFANA/grafana.ini" "./ssh-extracted-configs/grafana/grafana.ini" "grafana.ini"
    
    # Compare provisioning configs
    if [ -d "$RUNTIME_GRAFANA/provisioning" ] && [ -d "./ssh-extracted-configs/grafana/provisioning" ]; then
        echo ""
        echo "   📋 Provisioning comparison:"
        find "$RUNTIME_GRAFANA/provisioning" -type f | while read file; do
            rel_path=${file#$RUNTIME_GRAFANA/provisioning/}
            extracted_file="./ssh-extracted-configs/grafana/provisioning/$rel_path"
            compare_files "$file" "$extracted_file" "provisioning/$rel_path"
        done
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
    compare_files "$RUNTIME_BLACKBOX/blackbox.yml" "./ssh-extracted-configs/blackbox/blackbox.yml" "blackbox.yml"
else
    echo "   ❌ No blackbox config extracted"
fi

echo ""

# 5. Alertmanager Configuration Comparison
echo "🔸 Alertmanager Configuration:"
RUNTIME_ALERTMANAGER="./prometheus-stack/rootfs/etc/alertmanager"

if [ -d "./ssh-extracted-configs/alerting" ]; then
    echo "   Extracted: $(find ./ssh-extracted-configs/alerting -type f 2>/dev/null | wc -l) alerting files"
    
    # Compare alertmanager.yml
    compare_files "$RUNTIME_ALERTMANAGER/alertmanager.yml" "./ssh-extracted-configs/alerting/alertmanager.yml" "alertmanager.yml"
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
        find "./ssh-extracted-configs/$component" -type f | while read extracted_file; do
            # Try to find corresponding git file
            filename=$(basename "$extracted_file")
            rel_path=${extracted_file#./ssh-extracted-configs/$component/}
            
            found_in_git=false
            case $component in
                "dashboards")
                    [ -f "$RUNTIME_DASHBOARDS/$filename" ] || [ -f "$SOURCE_DASHBOARDS/$filename" ] && found_in_git=true
                    ;;
                "prometheus")
                    [ -f "$RUNTIME_PROMETHEUS/$rel_path" ] && found_in_git=true
                    ;;
                "grafana")
                    [ -f "$RUNTIME_GRAFANA/$rel_path" ] && found_in_git=true
                    ;;
                "blackbox")
                    [ -f "$RUNTIME_BLACKBOX/$rel_path" ] && found_in_git=true
                    ;;
                "alerting")
                    [ -f "$RUNTIME_ALERTMANAGER/$rel_path" ] && found_in_git=true
                    ;;
            esac
            
            if [ "$found_in_git" = false ]; then
                echo "   🆕 $component/$rel_path - NEW FILE"
                FOUND_NEW=true
            fi
        done
    fi
done

if [ "$FOUND_NEW" = false ]; then
    echo "   ✅ No new files found"
fi

echo ""
echo "🎯 Next Steps:"
echo "   • Review DIFFERENT files manually using suggested diff commands"
echo "   • Copy desired changes to git repository"  
echo "   • Update both source and runtime files as needed"
echo "   • Run ./test/full-test.sh to test changes"
echo "   • Commit changes with proper changelog"

echo ""
echo "💡 Typical sync workflow:"
echo "   1. Focus on files marked 🔄 DIFFERENT"
echo "   2. Review 🆕 NEW FILES to see if they should be added to git"
echo "   3. Update corresponding files in prometheus-stack/rootfs/etc/"
echo "   4. Update source files in dashboards/ if applicable"
echo "   5. Test the build to ensure everything works" 