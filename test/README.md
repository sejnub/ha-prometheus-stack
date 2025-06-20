# Testing Guide for Prometheus Stack Add-on

- [1. Test Directory Structure](#1-test-directory-structure)
- [2. Quick Start Testing](#2-quick-start-testing)
  - [2.1. Prerequisites](#21-prerequisites)
  - [2.2. Basic Testing Workflow](#22-basic-testing-workflow)
- [3. Detailed Script Documentation](#3-detailed-script-documentation)
  - [3.1. `build-test.sh` - Build and Test Script](#31-build-testsh---build-and-test-script)
  - [3.2. `docker-compose.dev.yml` - Development Configuration](#32-docker-composedevyml---development-configuration)
  - [3.3. `health-check.sh` - Health Verification](#33-health-checksh---health-verification)
  - [3.4. `test-config.sh` - Configuration Testing](#34-test-configsh---configuration-testing)
  - [3.5. `monitor.sh` - Resource Monitoring](#35-monitorsh---resource-monitoring)
  - [3.6. `cleanup.sh` - Environment Cleanup](#36-cleanupsh---environment-cleanup)
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

## 1. Test Directory Structure

This directory contains all testing tools and scripts for the Prometheus Stack Home Assistant add-on.

```
test/
├── README.md              # This file - testing guide
├── build-test.sh          # Build and run add-on for testing
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

### 2.2. Basic Testing Workflow
```bash
# 1. Build and start the add-on
./test/build-test.sh

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

### 3.1. `build-test.sh` - Build and Test Script
**Purpose**: Build and run the add-on locally for testing
**Usage**: `./test/build-test.sh`

**What it does**:
- Builds the Docker image with your add-on code
- Creates test configuration data
- Runs the container with proper port mapping
- Provides access URLs for testing

**Requirements**: Docker Desktop with WSL2 backend enabled

**Output**:
- Prometheus:        http://localhost:9090
- Alertmanager:      http://localhost:9093
- Blackbox Exporter: http://localhost:9115
- Karma:             http://localhost:8080

### 3.2. `docker-compose.dev.yml` - Development Configuration
**Purpose**: Alternative way to run the add-on for development
**Usage**: `docker-compose -f test/docker-compose.dev.yml up -d`

**Advantages over build-test.sh**:
- Better for long-term development
- Automatic restart on container failure
- Easier to modify configuration
- Better for team development

### 3.3. `health-check.sh` - Health Verification
**Purpose**: Verify that all services are running and healthy
**Usage**: `./test/health-check.sh`

**Health checks performed**:
- Prometheus: `/-/healthy` endpoint
- Alertmanager: `/-/healthy` endpoint
- Blackbox Exporter: `/metrics` endpoint
- Karma: Web interface availability

**Return codes**:
- `0`: All services healthy
- `1`: One or more services unhealthy

### 3.4. `test-config.sh` - Configuration Testing
**Purpose**: Test the add-on with different configuration scenarios
**Usage**: `./test/test-config.sh`

**Test scenarios**:
- Basic configuration validation
- Email format validation
- Receiver name validation
- Configuration file syntax checking
- Service restart with new configuration

**Test configurations**:
- Basic: `{"alertmanager_receiver":"default","alertmanager_to_email":"test@example.com"}`
- Production: `{"alertmanager_receiver":"prod-alerts","alertmanager_to_email":"admin@company.com"}`
- Multiple: `{"alertmanager_receiver":"team","alertmanager_to_email":"team@company.com"}`
- Special chars: `{"alertmanager_receiver":"test-receiver-123","alertmanager_to_email":"test+tag@example.com"}`

### 3.5. `monitor.sh` - Resource Monitoring
**Purpose**: Monitor resource usage and performance
**Usage**: `./test/monitor.sh [continuous]`

**Monitoring metrics**:
- Container CPU and Memory usage
- Disk space usage for `/data` directory
- Service response times
- Number of running processes
- Network connections

**Modes**:
- Single snapshot: `./test/monitor.sh`
- Continuous monitoring: `./test/monitor.sh continuous`

### 3.6. `cleanup.sh` - Environment Cleanup
**Purpose**: Clean up test containers, images, and data
**Usage**: `./test/cleanup.sh [--all] [--force]`

**Cleanup targets**:
- Test containers (prometheus-stack-test, prometheus-stack-dev)
- Test images (prometheus-stack-test)
- Test data directories (test-data/)
- Docker networks (if created)
- Docker volumes (if created)

**Options**:
- `--all`: Clean up everything including images and networks
- `--force`: Force stop and remove containers

## 4. Testing Workflows

### 4.1. Development Testing
```bash
# Start development environment
docker-compose -f test/docker-compose.dev.yml up -d

# Monitor continuously
./test/monitor.sh continuous

# Test configurations
./test/test-config.sh

# Health check
./test/health-check.sh
```

### 4.2. Quick Validation
```bash
# Quick build and test
./test/build-test.sh

# Verify health
./test/health-check.sh

# Clean up
./test/cleanup.sh
```

### 4.3. Performance Testing
```bash
# Start add-on
./test/build-test.sh

# Monitor performance
./test/monitor.sh continuous

# Test different configs
./test/test-config.sh

# Check resource usage
./test/monitor.sh
```

## 5. Troubleshooting

### 5.1. Common Issues

**Docker not running**
```bash
# Start Docker Desktop
# Or on Linux:
sudo systemctl start docker
```

**Port conflicts**
```bash
# Check what's using the ports
netstat -tulpn | grep :9090
netstat -tulpn | grep :9093
netstat -tulpn | grep :8080
netstat -tulpn | grep :9115
```

**Permission issues**
```bash
# Make scripts executable
chmod +x test/*.sh
```

**WSL2 performance issues**
```bash
# Check WSL2 memory allocation
cat /proc/meminfo | grep MemTotal
```

### 5.2. Debug Mode

Enable debug mode for more verbose output:

```bash
# Set debug environment variable
export DEBUG=1

# Run with debug output
./test/build-test.sh
```

## 6. Performance Optimization

### 6.1. WSL2 Configuration

For better performance in WSL2, create or edit `~/.wslconfig`:

```ini
[wsl2]
memory=4GB
processors=4
swap=2GB
```

### 6.2. Docker Configuration

Optimize Docker settings in Docker Desktop:

1. Go to **Settings** → **Resources**
2. Increase memory allocation to 4GB+
3. Increase CPU allocation to 4+
4. Enable **Use the WSL 2 based engine**

## 7. Next Steps

After successful testing:

1. **Create GitHub repository** and push your code
2. **Set up CI/CD** for automated testing
3. **Create releases** for version management
4. **Document deployment** procedures
5. **Set up monitoring** for the add-on itself

## 8. Notes

- All test scripts are designed to be idempotent
- Test data is stored in `test-data/` directory
- Containers are named with `-test` suffix to avoid conflicts
- Scripts use `set -e` to exit on any error
- All URLs use `localhost` for local testing

For more information, see the main [README.md](../README.md). 