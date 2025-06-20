# Testing Guide for Prometheus Stack Add-on

## 1. 📁 Test Directory Structure

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

## 2. 🚀 Quick Start Testing

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

## 3. 📋 Detailed Script Documentation

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
- Prometheus: http://localhost:9090
- Alertmanager: http://localhost:9093
- Karma: http://localhost:8080

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

## 4. 🔄 Testing Workflows

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

## 5. 🐛 Troubleshooting

### 5.1. Common Issues

1. **Docker not running**
   ```bash
   # Check Docker status
   docker info
   
   # Start Docker Desktop if needed
   ```

2. **Ports already in use**
   ```bash
   # Check what's using the ports
   sudo netstat -tulpn | grep :9090
   sudo netstat -tulpn | grep :9093
   sudo netstat -tulpn | grep :8080
   ```

3. **Container won't start**
   ```bash
   # Check container logs
   docker logs prometheus-stack-test
   
   # Run interactively for debugging
   docker run -it --rm prometheus-stack-test /bin/bash
   ```

4. **Permission issues**
   ```bash
   # Fix test-data permissions
   sudo chown -R $USER:$USER test-data/
   ```

### 5.2. Debug Mode
```bash
# Run container interactively
docker run -it --rm \
  -p 9090:9090 -p 9093:9093 -p 8080:8080 \
  -v $(pwd)/test-data:/data \
  prometheus-stack-test /bin/bash

# Inside container, run manually:
# /run.sh
```

## 6. 📊 Performance Optimization

### 6.1. WSL2 Configuration
```ini
# %UserProfile%\.wslconfig
[wsl2]
memory=8GB
processors=4
swap=2GB
localhostForwarding=true
```

### 6.2. Docker Configuration
```bash
# Create /etc/docker/daemon.json
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<EOF
{
  "storage-driver": "overlay2",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

# Restart Docker
sudo service docker restart
```

## 7. 🎯 Next Steps

1. **Test locally**: Use the provided scripts to test your add-on
2. **Deploy to Home Assistant**: Copy files to your Home Assistant machine
3. **Monitor performance**: Use the monitoring tools to ensure optimal performance
4. **Iterate**: Make improvements based on testing results

## 8. 📝 Notes

- All scripts are designed to work from the `test/` directory
- Scripts automatically detect running containers (both `prometheus-stack-test` and `prometheus-stack-dev`)
- Test data is stored in `../test-data/` relative to the test directory
- Scripts include comprehensive error handling and user feedback
- All scripts are documented with their purpose, usage, and requirements 