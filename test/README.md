# Testing Guide for Prometheus Stack Add-on

This directory contains all testing tools and comprehensive guides for the Prometheus Stack Home Assistant add-on.

- [1. Test Directory Structure](#1-test-directory-structure)
- [2. Quick Start Testing](#2-quick-start-testing)
  - [2.1. Prerequisites](#21-prerequisites)
  - [2.2. Configuration](#22-configuration)
  - [2.3. Basic Testing Workflow](#23-basic-testing-workflow)
- [3. Detailed Script Documentation](#3-detailed-script-documentation)
  - [3.1. `full-test.sh` - Complete Test Cycle](#31-full-testsh---complete-test-cycle)
  - [3.2. `build.sh` - Build Script](#32-buildsh---build-script)
  - [3.3. `docker-compose.dev.yml` - Development Configuration](#33-docker-composedevyml---development-configuration)
  - [3.4. `health-check.sh` - Health Verification](#34-health-checksh---health-verification)
  - [3.5. `test-config.sh` - Configuration Testing](#35-test-configsh---configuration-testing)
  - [3.6. `monitor.sh` - Resource Monitoring](#36-monitorsh---resource-monitoring)
  - [3.7. `cleanup.sh` - Environment Cleanup](#37-cleanupsh---environment-cleanup)
- [4. Testing Workflows](#4-testing-workflows)
  - [4.1. Development Testing](#41-development-testing)
  - [4.2. Quick Validation](#42-quick-validation)
  - [4.3. Performance Testing](#43-performance-testing)
- [5. Troubleshooting](#5-troubleshooting)
  - [5.1. Common Issues](#51-common-issues)
  - [5.2. Debug Mode](#52-debug-mode)
- [6. Performance Optimization](#6-performance-optimization)
  - [6.1. WSL2 Configuration](#61-wsl2-configuration)
  - [6.2. Docker Configuration](#62-docker-configuration)
- [7. Next Steps](#7-next-steps)
- [8. Notes](#8-notes)
- [9. Support](#9-support)
- [10. License](#10-license)

## 1. Test Directory Structure

This directory contains all testing tools and scripts for the Prometheus Stack Home Assistant add-on.

```txt
test/
├── README.md              # This file - comprehensive testing guide
├── full-test.sh           # Complete test cycle (cleanup → build → health check)
├── build.sh               # Build and run add-on for testing
├── docker-compose.dev.yml # Docker Compose for development
├── health-check.sh        # Verify all services are healthy
├── test-config.sh         # Test different configurations
├── monitor.sh             # Monitor resource usage
└── cleanup.sh             # Clean up test environment
```

## 2. Quick Start Testing

### 2.1. Prerequisites

- Docker Desktop for Windows (with WSL2 backend)
- WSL2 Ubuntu environment

### 2.2. Configuration

For testing with real Home Assistant instance:

1. Edit the `test-data/options.json` file with your actual values:

   ```json
   {
     "alertmanager_receiver": "default",
     "alertmanager_to_email": "your-email@example.com",
     "home_assistant_url": "http://supervisor/core",
     "home_assistant_token": "your-long-lived-access-token",
     "blackbox_targets": [
       {
         "name": "Home Assistant",
         "url": "http://supervisor/core"
       }
     ]
   }
   ```

**Note:** The `options.json` file is automatically created with default values when you first run `build.sh`. Your changes to this file will be preserved between test runs, and the file is properly gitignored to keep your credentials safe.

### 2.3. Basic Testing Workflow

```bash
# Full automated test cycle (recommended)
./test/full-test.sh

# OR run individual steps:
# 1. Build and start the add-on
./test/build.sh

# 2. Check if all services are healthy
./test/health-check.sh

# 3. Test different configurations
./test/test-config.sh

# 4. Monitor performance
./test/monitor.sh

# 5. Clean up when done
./test/cleanup.sh
```

## 3. Detailed Script Documentation

### 3.1. `full-test.sh` - Complete Test Cycle

- **Purpose**: Run the complete test cycle automatically
- **Usage**: `./test/full-test.sh`
- **What it does**:
  - Runs cleanup.sh to clean up any existing containers
  - Runs build.sh to build and start the add-on
  - Runs health-check.sh to verify all services are healthy
  - Provides comprehensive status reporting with colored output
  - Stops at the first failure and provides helpful error messages
- **Benefits**:
  - One command to run all testing phases
  - Consistent testing workflow
  - Automated error handling and reporting
  - Saves time during development and CI/CD
- **Output**: Colored status messages for each phase with final summary

### 3.2. `build.sh` - Build Script

- **Purpose**: Build and run the add-on locally for testing
- **Usage**: `./test/build.sh`
- **What it does**:
  - Builds the Docker image with your add-on code
  - Creates test configuration data (if not exists)
  - Preserves your existing configuration between runs
  - Runs the container with proper port mapping
  - Provides access URLs for testing
- **Requirements**: Docker Desktop with WSL2 backend enabled
- **Output**:
  - Prometheus: <http://localhost:9090>
  - Alertmanager: <http://localhost:9093>
  - Blackbox Exporter: <http://localhost:9115>
  - Karma: <http://localhost:8080>

### 3.3. `docker-compose.dev.yml` - Development Configuration

- **Purpose**: Alternative way to run the add-on for development
- **Usage**: `docker-compose -f test/docker-compose.dev.yml up -d`
- **Advantages over build.sh**:
  - Better for long-term development
  - Automatic restart on container failure
  - Easier to modify configuration
  - Better for team development

### 3.4. `health-check.sh` - Health Verification

- **Purpose**: Verify that all services are running and healthy
- **Usage**: `./test/health-check.sh`
- **Health checks performed**:
  - Prometheus: `/-/healthy` endpoint
  - Alertmanager: `/-/healthy` endpoint
  - Blackbox Exporter: `/metrics` endpoint
  - Karma: Web interface availability
- **Return codes**:
  - `0`: All services healthy
  - `1`: One or more services unhealthy

### 3.5. `test-config.sh` - Configuration Testing

- **Purpose**: Test the add-on with different configuration scenarios
- **Usage**: `./test/test-config.sh`
- **Test scenarios**:
  - Basic configuration validation
  - Email format validation
  - Receiver name validation
  - Configuration file syntax checking
  - Service restart with new configuration
- **Test configurations**:
  - Basic: `{"alertmanager_receiver":"default","alertmanager_to_email":"test@example.com"}`
  - Production: `{"alertmanager_receiver":"prod-alerts","alertmanager_to_email":"admin@company.com"}`
  - Multiple: `{"alertmanager_receiver":"team","alertmanager_to_email":"team@company.com"}`
  - Special chars: `{"alertmanager_receiver":"test-receiver-123","alertmanager_to_email":"test+tag@example.com"}`

### 3.6. `monitor.sh` - Resource Monitoring

- **Purpose**: Monitor resource usage and performance
- **Usage**: `./test/monitor.sh [continuous]`
- **Monitoring metrics**:
  - Container CPU and Memory usage
  - Disk space usage for `/data` directory
  - Service response times
  - Number of running processes
  - Network connections
- **Modes**:
  - Single snapshot: `./test/monitor.sh`
  - Continuous monitoring: `./test/monitor.sh continuous`

### 3.7. `cleanup.sh` - Environment Cleanup

- **Purpose**: Clean up test containers, images, and data
- **Usage**: `./test/cleanup.sh [--all] [--force]`
- **Cleanup targets**:
  - Test containers (prometheus-stack-test, prometheus-stack-dev)
  - Test images (prometheus-stack-test)
  - Test data directories (test-data/)
  - Docker networks (if created)
  - Docker volumes (if created)
- **Options**:
  - `--all`: Clean up everything including images and networks
  - `--force`: Force stop containers (use with caution)

## 4. Testing Workflows

### 4.1. Development Testing

For active development with frequent changes:

```bash
# Development cycle
./test/cleanup.sh
./test/build.sh
./test/health-check.sh
./test/monitor.sh
```

### 4.2. Quick Validation

For quick validation after small changes:

```bash
# Quick test cycle
./test/full-test.sh
```

### 4.3. Performance Testing

For performance analysis:

```bash
./test/build.sh
./test/monitor.sh continuous
# Let it run for a while, then Ctrl+C
./test/cleanup.sh
```

## 5. Troubleshooting

### 5.1. Common Issues

- **Container won't start**: Check Docker logs with `docker logs prometheus-stack-test`
- **Services unhealthy**: Use `./test/health-check.sh` for detailed diagnosis
- **Port conflicts**: Ensure ports 9090, 9093, 9115, 8080, 80 are available
- **WSL2 issues**: Restart Docker Desktop and WSL2

### 5.2. Debug Mode

Enable debug mode by setting environment variables:

```bash
export DEBUG=1
./test/build.sh
```

## 6. Performance Optimization

### 6.1. WSL2 Configuration

Optimize WSL2 for better performance:

- Allocate sufficient memory (4GB+ recommended)
- Enable Docker Desktop WSL2 integration
- Use WSL2 file system for better I/O performance

### 6.2. Docker Configuration

Docker optimization settings:

- Increase memory allocation to 4GB+
- Enable experimental features
- Use BuildKit for faster builds

## 7. Next Steps

After successful testing:

1. Deploy to Home Assistant as an add-on
2. Configure production monitoring settings
3. Set up alerts and notifications
4. Import Grafana dashboards

## 8. Notes

- Test data is automatically preserved between runs
- All scripts are designed to be run from project root or test directory
- Scripts include comprehensive error handling and colored output
- WSL2 and Docker Desktop are required for full functionality

## 9. Support

For testing issues:

- [Documentation](https://github.com/sejnub/ha-prometheus-stack/wiki)
- [Issue Tracker](https://github.com/sejnub/ha-prometheus-stack/issues)

## 10. License

MIT License - see [LICENSE](../LICENSE) file for details
