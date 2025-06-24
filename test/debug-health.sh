#!/bin/bash

# =============================================================================
# DEBUG HEALTH CHECK - PROMETHEUS STACK ADD-ON
# =============================================================================
# PURPOSE: Run health check with maximum debug output
# USAGE:   ./test/debug-health.sh
# 
# This script runs the health check with additional debugging information
# to help troubleshoot issues, especially in CI/GitHub Actions environments.
# =============================================================================

set -e

# Enable verbose output
set -x

# Get the absolute path of the script directory
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$TEST_DIR/.." && pwd)"

echo "🐛 DEBUG HEALTH CHECK - PROMETHEUS STACK"
echo "========================================"
echo "📍 Running from: $TEST_DIR"
echo "📁 Project root: $PROJECT_ROOT"
echo ""

# Run the main health check with debug output
cd "$PROJECT_ROOT"
exec "$TEST_DIR/health-check.sh" 