#!/bin/bash
# sync-to-repo.sh - Automatically sync changes from running instance to git repository

set -e  # Exit on any error

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Load configuration and detect mode
load_env
set_defaults
MODE=$(detect_mode)

# Show configuration
show_config "$MODE"

# Function to backup a file before overwriting
backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$file" "$backup"
        print_status "$YELLOW" "   📦 Backed up: $file → $backup"
    fi
}

# Function to sync a file with backup and confirmation
sync_file() {
    local source="$1"
    local target="$2"
    local description="$3"
    
    if [ ! -f "$source" ]; then
        print_status "$RED" "   ❌ Source file not found: $source"
        return 1
    fi
    
    if [ -f "$target" ]; then
        if diff -q "$source" "$target" > /dev/null; then
            print_status "$GREEN" "   ✅ $description - IDENTICAL (no sync needed)"
            return 0
        else
            print_status "$YELLOW" "   🔄 $description - DIFFERENT (will sync)"
            backup_file "$target"
        fi
    else
        print_status "$BLUE" "   🆕 $description - NEW FILE (will create)"
        # Create directory if it doesn't exist
        mkdir -p "$(dirname "$target")"
    fi
    
    # Copy the file
    cp "$source" "$target"
    print_status "$GREEN" "   ✅ Synced: $source → $target"
    return 0
}

# Function to sync dashboard files
sync_dashboards() {
    print_status "$BLUE" "📊 Syncing Dashboard Files..."
    
    if [ ! -d "./$EXTRACTED_DIR/dashboards/dashboards" ]; then
        print_status "$RED" "   ❌ No extracted dashboards found"
        return 1
    fi
    
    local synced_count=0
    for dashboard in ./$EXTRACTED_DIR/dashboards/dashboards/*.json; do
        if [ -f "$dashboard" ]; then
            local filename=$(basename "$dashboard")
            local source_dashboards="./dashboards/$filename"
            local runtime_dashboards="./prometheus-stack/rootfs/etc/grafana/provisioning/dashboards/$filename"
            
            # Sync to source dashboards
            if sync_file "$dashboard" "$source_dashboards" "Dashboard: $filename (source)"; then
                ((synced_count++))
            fi
            
            # Sync to runtime dashboards
            if sync_file "$dashboard" "$runtime_dashboards" "Dashboard: $filename (runtime)"; then
                ((synced_count++))
            fi
        fi
    done
    
    print_status "$GREEN" "   📊 Synced $synced_count dashboard operations"
}

# Function to sync Prometheus configuration
sync_prometheus() {
    print_status "$BLUE" "🎯 Syncing Prometheus Configuration..."
    
    local prometheus_dir="./$EXTRACTED_DIR/prometheus"
    if [ ! -d "$prometheus_dir" ]; then
        print_status "$RED" "   ❌ No extracted prometheus config found"
        return 1
    fi
    
    local synced_count=0
    
    # Sync prometheus.yml
    if [ -f "$prometheus_dir/prometheus.yml" ]; then
        # Sync to source
        if sync_file "$prometheus_dir/prometheus.yml" "./prometheus-stack/prometheus.yml" "prometheus.yml (source)"; then
            ((synced_count++))
        fi
        
        # Sync to runtime
        if sync_file "$prometheus_dir/prometheus.yml" "./prometheus-stack/rootfs/etc/prometheus/prometheus.yml" "prometheus.yml (runtime)"; then
            ((synced_count++))
        fi
    fi
    
    # Sync alert rules
    if [ -d "$prometheus_dir/rules" ]; then
        for rule_file in "$prometheus_dir/rules"/*.yml; do
            if [ -f "$rule_file" ]; then
                local filename=$(basename "$rule_file")
                local target="./prometheus-stack/rootfs/etc/prometheus/rules/$filename"
                
                if sync_file "$rule_file" "$target" "Alert rule: $filename"; then
                    ((synced_count++))
                fi
            fi
        done
    fi
    
    print_status "$GREEN" "   🎯 Synced $synced_count prometheus operations"
}

# Function to sync Grafana configuration
sync_grafana() {
    print_status "$BLUE" "📊 Syncing Grafana Configuration..."
    
    local grafana_dir="./$EXTRACTED_DIR/grafana"
    if [ ! -d "$grafana_dir" ]; then
        print_status "$RED" "   ❌ No extracted grafana config found"
        return 1
    fi
    
    local synced_count=0
    
    # Sync grafana.ini
    if [ -f "$grafana_dir/grafana.ini" ]; then
        # Sync to source
        if sync_file "$grafana_dir/grafana.ini" "./prometheus-stack/grafana.ini" "grafana.ini (source)"; then
            ((synced_count++))
        fi
        
        # Sync to runtime
        if sync_file "$grafana_dir/grafana.ini" "./prometheus-stack/rootfs/etc/grafana/grafana.ini" "grafana.ini (runtime)"; then
            ((synced_count++))
        fi
    fi
    
    # Sync provisioning files
    if [ -d "$grafana_dir/provisioning" ]; then
        for prov_file in "$grafana_dir/provisioning"/*/*.yml; do
            if [ -f "$prov_file" ]; then
                local filename=$(basename "$prov_file")
                local subdir=$(basename "$(dirname "$prov_file")")
                local target="./prometheus-stack/rootfs/etc/grafana/provisioning/$subdir/$filename"
                
                if sync_file "$prov_file" "$target" "Grafana provisioning: $subdir/$filename"; then
                    ((synced_count++))
                fi
            fi
        done
    fi
    
    print_status "$GREEN" "   📊 Synced $synced_count grafana operations"
}

# Function to sync Blackbox configuration
sync_blackbox() {
    print_status "$BLUE" "🔎 Syncing Blackbox Configuration..."
    
    local blackbox_dir="./$EXTRACTED_DIR/blackbox"
    if [ ! -d "$blackbox_dir" ]; then
        print_status "$RED" "   ❌ No extracted blackbox config found"
        return 1
    fi
    
    local synced_count=0
    
    # Sync blackbox.yml
    if [ -f "$blackbox_dir/blackbox.yml" ]; then
        # Sync to source
        if sync_file "$blackbox_dir/blackbox.yml" "./prometheus-stack/blackbox.yml" "blackbox.yml (source)"; then
            ((synced_count++))
        fi
        
        # Sync to runtime
        if sync_file "$blackbox_dir/blackbox.yml" "./prometheus-stack/rootfs/etc/blackbox_exporter/blackbox.yml" "blackbox.yml (runtime)"; then
            ((synced_count++))
        fi
    fi
    
    print_status "$GREEN" "   🔎 Synced $synced_count blackbox operations"
}

# Function to handle dynamic configurations (like alertmanager)
handle_dynamic_configs() {
    print_status "$BLUE" "🚨 Handling Dynamic Configurations..."
    
    local alerting_dir="./$EXTRACTED_DIR/alerting"
    if [ ! -d "$alerting_dir" ]; then
        print_status "$RED" "   ❌ No extracted alerting config found"
        return 1
    fi
    
    if [ -f "$alerting_dir/alertmanager.yml" ]; then
        print_status "$YELLOW" "   📋 alertmanager.yml is dynamically generated from options.json"
        print_status "$YELLOW" "   💡 To sync alertmanager changes, you need to:"
        print_status "$YELLOW" "      1. Review the generated config: cat $alerting_dir/alertmanager.yml"
        print_status "$YELLOW" "      2. Update ../test-data/options.json accordingly"
        print_status "$YELLOW" "      3. Rebuild the container to regenerate the config"
    fi
}

# Function to show sync summary
show_summary() {
    print_status "$BLUE" ""
    print_status "$BLUE" "📋 Sync Summary:"
    print_status "$BLUE" "================"
    print_status "$GREEN" "✅ Sync completed successfully!"
    print_status "$BLUE" ""
    print_status "$BLUE" "📁 Files synced to:"
    print_status "$BLUE" "   • Source files: ./dashboards/, ./prometheus-stack/"
    print_status "$BLUE" "   • Runtime files: ./prometheus-stack/rootfs/etc/"
    print_status "$BLUE" ""
    print_status "$BLUE" "📦 Backups created:"
    print_status "$BLUE" "   • Check for .backup.* files in the repository"
    print_status "$BLUE" ""
    print_status "$YELLOW" "🚨 Next Steps:"
    print_status "$YELLOW" "   1. Review the changes: git diff"
    print_status "$YELLOW" "   2. Test the changes: cd .. && ./test/build.sh"
    print_status "$YELLOW" "   3. Commit when satisfied: git add . && git commit -m 'Sync changes from running instance'"
    print_status "$YELLOW" "   4. Clean up backups if everything works: find . -name '*.backup.*' -delete"
}

# Main script logic
main() {
    print_status "$BLUE" "🔄 Automatic Sync Tool - Copying changes from running instance to repository"
    print_status "$BLUE" "=================================================================="
    
    # Check if extraction has been done
    if [ ! -d "./$EXTRACTED_DIR" ]; then
        print_status "$RED" "❌ No extracted files found!"
        print_status "$RED" "📥 Run ./s2_extract-configs.sh first"
        exit 1
    fi
    
    # Check if we're in the right directory
    if [ ! -f "./s2_extract-configs.sh" ]; then
        print_status "$RED" "❌ Please run this script from the sync-tools directory"
        exit 1
    fi
    
    # Check if git repository exists
    if [ ! -d "../.git" ]; then
        print_status "$RED" "❌ Not in a git repository. Please run from the project root."
        exit 1
    fi
    
    print_status "$BLUE" "🔍 Starting automatic sync process..."
    print_status "$BLUE" "📁 Extracted files: ./$EXTRACTED_DIR/"
    print_status "$BLUE" "📁 Target repository: ../"
    print_status "$BLUE" ""
    
    # Create backup directory
    local backup_dir="$SYNC_BACKUP_DIR/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    print_status "$YELLOW" "📦 Backups will be saved to: $backup_dir"
    print_status "$BLUE" ""
    
    # Sync each component
    local total_operations=0
    local components_processed=0
    
    # Sync dashboards
    if sync_dashboards; then
        ((total_operations++))
    fi
    ((components_processed++))
    
    # Sync prometheus
    if sync_prometheus; then
        ((total_operations++))
    fi
    ((components_processed++))
    
    # Sync grafana
    if sync_grafana; then
        ((total_operations++))
    fi
    ((components_processed++))
    
    # Sync blackbox
    if sync_blackbox; then
        ((total_operations++))
    fi
    ((components_processed++))
    
    # Handle dynamic configs
    handle_dynamic_configs
    
    print_status "$BLUE" ""
    print_status "$GREEN" "✅ Sync process completed!"
    print_status "$BLUE" "📊 Components processed: $components_processed"
    print_status "$BLUE" "📊 Files synced: $total_operations"
    
    # Show summary only if there were actual operations
    if [ $total_operations -gt 0 ]; then
        show_summary
        print_status_icon "OK" "Repository sync completed successfully - $total_operations operations performed"
    else
        print_status "$YELLOW" ""
        print_status "$YELLOW" "💡 No files were synced. This could mean:"
        print_status "$YELLOW" "   • All files are identical (no changes needed)"
        print_status "$YELLOW" "   • No extracted files were found in expected locations"
        print_status "$YELLOW" "   • Run ./s3_compare-configs.sh first to see what changed"
        print_status_icon "WARN" "Repository sync completed - No files were synced (all files identical)"
    fi
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Automatically sync changes from running instance to git repository"
        echo ""
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --dry-run      Show what would be synced without actually copying"
        echo ""
        echo "Prerequisites:"
        echo "  1. Run ./s2_extract-configs.sh first to extract current configs"
        echo "  2. Run ./s3_compare-configs.sh to see what changed"
        echo "  3. Run this script to sync the changes"
        echo ""
        echo "Workflow:"
        echo "  ./s2_extract-configs.sh  # Extract from running instance"
        echo "  ./s3_compare-configs.sh  # See what changed"
        echo "  ./s4_sync-to-repo.sh     # This script - sync to repository"
        echo "  git diff              # Review changes"
        echo "  ./test/build.sh  # Test changes"
        echo "  git commit            # Commit when satisfied"
        exit 0
        ;;
    --dry-run)
        print_status "$YELLOW" "🔍 DRY RUN MODE - No files will be actually copied"
        print_status "$YELLOW" "This would show what would be synced"
        # TODO: Implement dry-run mode
        print_status "$YELLOW" "Dry-run mode not yet implemented. Use --help for usage."
        exit 0
        ;;
    "")
        # No arguments, run main function
        main
        ;;
    *)
        print_status "$RED" "❌ Unknown option: $1"
        print_status "$RED" "Use --help for usage information"
        exit 1
        ;;
esac 