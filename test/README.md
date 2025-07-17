# Testing Guide for InfluxDB Stack Add-on

This directory contains all testing tools and comprehensive guides for the InfluxDB Stack Home Assistant add-on.

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

This directory contains all testing tools and scripts for the InfluxDB Stack Home Assistant add-on.

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

- **Docker Desktop** with WSL2 backend enabled
- **Git** for cloning the repository
- **Bash shell** (WSL2, Linux, or macOS)
- **At least 4GB RAM** for smooth operation
- **Network connectivity** for downloading dependencies

### 2.2. Configuration

No additional configuration is required for basic testing. The test scripts use sensible defaults.

### 2.3. Basic Testing Workflow

The fastest way to test the InfluxDB Stack add-on:

```bash
# Clone the repository
git clone https://github.com/sejnub/ha-influxdb-stack.git
cd ha-influxdb-stack

# Run the complete test cycle
./test/full-test.sh
```

This single command will:
1. Clean up any existing test environment
2. Build the Docker image
3. Start the container with test configuration
4. Verify all services are healthy
5. Provide access URLs for manual testing

## 3. Detailed Script Documentation

### 3.1. `full-test.sh` - Complete Test Cycle

**Purpose**: Runs the complete test cycle automatically.

**Usage**:
```bash
./test/full-test.sh
```

**What it does**:
1. Runs `cleanup.sh` to clean up any existing test environment
2. Runs `build.sh` to build and start the container
3. Runs `health-check.sh` to verify all services are healthy
4. Provides a summary of results and access URLs

**Output**: Detailed progress information and final status report.

### 3.2. `build.sh` - Build Script

**Purpose**: Build the Docker image and start the container for testing.

**Usage**:
```bash
./test/build.sh
```

**What it does**:
1. Builds the Docker image from the Dockerfile
2. Creates test configuration (`options.json`)
3. Starts the container with proper port mappings
4. Provides service access URLs

**Ports exposed**:
- `8086` - InfluxDB UI
- `3000` - Grafana
- `8443` - VS Code
- `80` - NGINX ingress

### 3.3. `docker-compose.dev.yml` - Development Configuration

**Purpose**: Alternative development workflow using Docker Compose.

**Usage**:
```bash
docker-compose -f test/docker-compose.dev.yml up -d
```

**Advantages**:
- Automatic container restart on failure
- Better for long-term development
- Easier to modify configuration
- Better for team development

### 3.4. `health-check.sh` - Health Verification

**Purpose**: Comprehensive health check of all services.

**Usage**:
```bash
./test/health-check.sh
```

**What it checks**:
- InfluxDB health endpoint
- Grafana database connectivity
- VS Code server availability
- NGINX status and proxy paths
- Configuration file presence
- Data directory structure

### 3.5. `test-config.sh` - Configuration Testing

**Purpose**: Test different configuration scenarios.

**Usage**:
```bash
./test/test-config.sh
```

**Test scenarios**:
- InfluxDB organization and bucket configuration
- Grafana admin password validation
- Configuration file generation
- Service restart with new configuration

### 3.6. `monitor.sh` - Resource Monitoring

**Purpose**: Monitor resource usage and performance.

**Usage**:
```bash
./test/monitor.sh           # Single snapshot
./test/monitor.sh continuous # Continuous monitoring
```

**Monitoring metrics**:
- Container CPU and memory usage
- Disk space usage for data directories
- Service response times
- Network connections
- Process information

### 3.7. `cleanup.sh` - Environment Cleanup

**Purpose**: Clean up test containers, images, and data.

**Usage**:
```bash
./test/cleanup.sh           # Basic cleanup
./test/cleanup.sh --all     # Clean everything including images
./test/cleanup.sh --force   # Force cleanup stuck containers
```

**Cleanup targets**:
- Test containers (`influxdb-stack-test`, `influxdb-stack-dev`)
- Test images (`influxdb-stack-test`)
- Test data directories (`test-data/`)
- Docker networks and volumes (with `--all`)

## 4. Testing Workflows

### 4.1. Development Testing

For active development with frequent changes:

```bash
# Initial setup
./test/full-test.sh

# During development (after code changes)
./test/build.sh
./test/health-check.sh

# Monitor performance
./test/monitor.sh continuous
```

### 4.2. Quick Validation

For quick validation of changes:

```bash
# Quick test cycle
./test/cleanup.sh && ./test/build.sh && ./test/health-check.sh
```

### 4.3. Performance Testing

For performance analysis:

```bash
# Start monitoring in background
./test/monitor.sh continuous &

# Run test cycle
./test/full-test.sh

# Stop monitoring
pkill -f monitor.sh
```

## 5. Troubleshooting

### 5.1. Common Issues

**Container fails to start**:
```bash
# Check Docker status
docker info

# View container logs
docker logs influxdb-stack-test

# Clean up and retry
./test/cleanup.sh --force
./test/build.sh
```

**Services not responding**:
```bash
# Check service status
./test/health-check.sh

# Monitor resource usage
./test/monitor.sh

# Check individual service logs
docker exec influxdb-stack-test journalctl -u influxdb
```

**Port conflicts**:
```bash
# Check what's using the ports
netstat -tulpn | grep :8086
netstat -tulpn | grep :3000

# Stop conflicting services or use different ports
```

### 5.2. Debug Mode

Enable verbose logging in any script:

```bash
# Set debug mode
export DEBUG=true

# Run with verbose output
./test/build.sh
```

## 6. Performance Optimization

### 6.1. WSL2 Configuration

For optimal performance on Windows with WSL2:

```bash
# Increase WSL2 memory limit
echo '[wsl2]' >> ~/.wslconfig
echo 'memory=8GB' >> ~/.wslconfig
echo 'processors=4' >> ~/.wslconfig

# Restart WSL2
wsl --shutdown
```

### 6.2. Docker Configuration

Optimize Docker settings:

```bash
# Increase Docker memory limit (Docker Desktop Settings)
# - Resources > Advanced > Memory: 4GB+
# - Resources > Advanced > CPUs: 2+

# Enable BuildKit for faster builds
export DOCKER_BUILDKIT=1
```

## 7. Next Steps

After successful testing:

1. **Manual Testing**: Access the services and test functionality
2. **Integration Testing**: Test with Home Assistant
3. **Performance Testing**: Monitor resource usage under load
4. **Security Testing**: Validate security configurations

## 8. Notes

- Test scripts are designed to be idempotent (safe to run multiple times)
- All test data is stored in `test-data/` directory
- Container names are prefixed with `influxdb-stack-` to avoid conflicts
- Scripts work in both WSL2 and native Linux environments

## 9. Support

For testing issues:
- Check the troubleshooting section above
- Review container logs: `docker logs influxdb-stack-test`
- Open an issue on GitHub with test output

## 10. License

These testing tools are part of the InfluxDB Stack add-on project and are licensed under the MIT License.
