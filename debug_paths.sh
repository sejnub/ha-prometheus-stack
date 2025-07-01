#!/bin/bash

echo "=== Current working directory ==="
pwd

echo ""
echo "=== Testing file paths ==="
for file in 06-addon-components.json 03-blackbox-exporter.json; do
    echo "--- $file ---"
    source_path="./prometheus-stack/rootfs/etc/grafana/provisioning/dashboards/$file"
    target_path="./sync-tools/ssh-extracted-configs/dashboards/dashboards/$file"
    
    echo "Source path: $source_path"
    echo "Target path: $target_path"
    echo "Source exists: $([ -f "$source_path" ] && echo "YES" || echo "NO")"
    echo "Target exists: $([ -f "$target_path" ] && echo "YES" || echo "NO")"
    
    if [ -f "$source_path" ] && [ -f "$target_path" ]; then
        echo "Source iconColor: $(grep iconColor "$source_path")"
        echo "Target iconColor: $(grep iconColor "$target_path")"
        echo "Files are different: $(! diff -q "$source_path" "$target_path" >/dev/null && echo "YES" || echo "NO")"
    fi
    echo ""
done
