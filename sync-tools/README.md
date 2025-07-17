# InfluxDB Stack Sync Tools

Advanced configuration synchronization tools for the InfluxDB Stack Home Assistant addon.

## Overview

The InfluxDB Stack sync tools provide a comprehensive solution for synchronizing configuration files between your development environment and running InfluxDB Stack containers. These tools work in both **Test Mode** (local development) and **Addon Mode** (remote Home Assistant).

### What These Tools Do

1. **Extract** configuration files from running containers
2. **Compare** runtime configurations with repository source files  
3. **Sync** changes back to the repository with automatic backups
4. **Test** connectivity and file access

## Architecture

The InfluxDB Stack consists of these core services:

- **InfluxDB 2.x** (8086) - Time series database and primary UI
- **Grafana** (3000) - Visualization and alerting platform
- **NGINX** (80) - Reverse proxy and ingress controller
- **VS Code** (8443) - Development environment

## Quick Start

### 1. Setup Environment

Create a `.env` file in the `sync-tools/` directory:

```bash
# Home Assistant Connection (for Addon Mode)
HA_HOSTNAME=homeassistant.local
HA_SSH_USER=root
HA_SSH_KEY=~/.ssh/id_rsa

# Container Settings
LOCAL_CONTAINER_NAME=influxdb-stack-test
REMOTE_CONTAINER_NAME=addon_local_influxdb_stack

# Sync Settings
VERBOSE=true
DRY_RUN=false
```

### 2. Run the Tools

```bash
# Test connectivity first
./sync-tools/s1_quick-ssh-test.sh

# Extract all configurations from running container
./sync-tools/s2_extract-configs.sh

# Compare extracted configs with repository
./sync-tools/s3_compare-configs.sh

# Sync changes back to repository
./sync-tools/s4_sync-to-repo.sh
```

## Tool Details

### s1_quick-ssh-test.sh
**Purpose**: Test SSH connectivity and basic file access

- Tests SSH connection to Home Assistant (Addon Mode)
- Verifies container accessibility
- Checks configuration file permissions
- Tests service health endpoints

**Usage**:
```bash
./sync-tools/s1_quick-ssh-test.sh
```

### s2_extract-configs.sh
**Purpose**: Extract configuration files from running container

**Extracts**:
- Grafana configuration (`grafana.ini`, datasources, dashboards)
- InfluxDB configuration files (if any)
- NGINX configuration (`nginx.conf`, `ingress.conf`)
- Dashboard JSON files

**Usage**:
```bash
./sync-tools/s2_extract-configs.sh
```

**Output**: Files organized in `./ssh-extracted-configs/`

### s3_compare-configs.sh
**Purpose**: Compare extracted configurations with repository

**Compares**:
- **TEMPLATE_FILE**: Template files in repository root
- **STATIC_FILE**: Files in `rootfs/etc/` structure
- **GENERATED_TRACKABLE**: Runtime-generated files (tracking only)

**Usage**:
```bash
./sync-tools/s3_compare-configs.sh
```

**Output**: Detailed diff report with sync recommendations

### s4_sync-to-repo.sh
**Purpose**: Sync extracted configurations back to repository

**Features**:
- Automatic backup creation
- Dry-run mode for safety
- Git commit suggestions
- Priority-based processing

**Usage**:
```bash
# Dry run (recommended first)
./sync-tools/s4_sync-to-repo.sh --dry-run

# Apply changes
./sync-tools/s4_sync-to-repo.sh
```

## Operating Modes

### Test Mode (Local Development)
- **Container**: `influxdb-stack-test`
- **Access**: Direct Docker commands
- **Use Case**: Local development and testing

**Setup**:
```bash
# Start test container
./test/build.sh

# Run sync tools
./sync-tools/s1_quick-ssh-test.sh
```

### Addon Mode (Remote Home Assistant)
- **Container**: `addon_local_influxdb_stack`
- **Access**: SSH + Docker commands
- **Use Case**: Production addon synchronization

**Setup**:
1. Enable SSH access on Home Assistant
2. Configure `.env` file with SSH credentials
3. Run sync tools

## Configuration Files

### config-files.yml
Defines how each configuration file should be handled:

```yaml
"grafana.ini":
  type: TEMPLATE_FILE
  runtime_path: grafana
  source_path: influxdb-stack
  extracted_path: grafana
  description: "Grafana server configuration template"
  priority: 1

"influxdb.yml":
  type: STATIC_FILE
  runtime_path: grafana/provisioning/datasources
  source_path: influxdb-stack/rootfs/etc/grafana/provisioning/datasources
  extracted_path: grafana/datasources
  description: "InfluxDB datasource configuration"
  priority: 2
```

### File Types

- **TEMPLATE_FILE**: Template files in repository root (e.g., `grafana.ini`)
- **STATIC_FILE**: Static files copied from `rootfs/etc/`
- **GENERATED_TRACKABLE**: Runtime-generated files (track changes only)

## Directory Structure

```
sync-tools/
├── config.sh                 # Central configuration library
├── config-files.yml          # File handling definitions
├── s1_quick-ssh-test.sh      # Connectivity testing
├── s2_extract-configs.sh     # Configuration extraction  
├── s3_compare-configs.sh     # Configuration comparison
├── s4_sync-to-repo.sh        # Repository synchronization
├── .env                      # Environment configuration
└── README.md                 # This file

Generated directories:
├── ssh-extracted-configs/    # Extracted configurations
│   ├── grafana/             # Grafana configs
│   ├── nginx/               # NGINX configs
│   ├── influxdb/            # InfluxDB configs
│   └── dashboards/          # Dashboard files
└── sync-backups/            # Automatic backups
```

## Best Practices

### Development Workflow
1. Make changes to InfluxDB Stack configuration
2. Test changes in running container
3. Extract configurations with `s2_extract-configs.sh`
4. Compare with repository using `s3_compare-configs.sh`
5. Sync to repository with `s4_sync-to-repo.sh`
6. Commit changes to git

### Safety Features
- **Automatic backups**: All synced files are backed up
- **Dry-run mode**: Preview changes before applying
- **Diff previews**: See exactly what will change
- **Error handling**: Graceful failure with clear messages

### Troubleshooting

**SSH Connection Issues**:
```bash
# Test SSH manually
ssh -i ~/.ssh/id_rsa root@homeassistant.local

# Check container status
docker ps | grep influxdb-stack
```

**File Permission Issues**:
```bash
# Check file permissions in container
docker exec <container> ls -la /etc/grafana/
```

**Missing Files**:
```bash
# Verify container has expected files
./sync-tools/s1_quick-ssh-test.sh
```

## Migration from Prometheus Stack

If migrating from the old Prometheus Stack sync tools:

1. **Update container names**: `prometheus-stack-test` → `influxdb-stack-test`
2. **Update file paths**: Remove Prometheus/Alertmanager references
3. **Update config-files.yml**: Use new InfluxDB Stack file definitions
4. **Re-run extraction**: Extract fresh configurations from InfluxDB Stack

## Contributing

When adding new configuration files:

1. Update `config-files.yml` with file definition
2. Test with all four sync tools
3. Update this README if needed
4. Test in both Test Mode and Addon Mode

## Support

For issues with the sync tools:
1. Check the tool output for error messages
2. Verify SSH connectivity with `s1_quick-ssh-test.sh`
3. Check container logs: `docker logs <container>`
4. Review the configuration in `.env` and `config-files.yml`
