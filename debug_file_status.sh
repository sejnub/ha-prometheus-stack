#!/bin/bash

# Source the script to get access to functions
source ./sync-tools/s3_compare-configs.sh

# Add debug output to see what's in file_status
echo "=== DEBUG: File status array ==="
for filename in "${!file_status[@]}"; do
    echo "File: $filename -> Status: ${file_status[$filename]}"
done
echo "=== END DEBUG ==="
