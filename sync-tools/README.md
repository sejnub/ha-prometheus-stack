# Addon Configuration Sync Tools

**Intelligent tools for syncing configuration changes** between your development environment and Home Assistant. Works seamlessly in both **Test-Mode** and **Addon-Mode**.

## 🎯 What These Tools Do

The Prometheus Stack addon stores all configuration files inside Docker containers rather than in `/addon_configs/`. These tools automatically detect your environment and extract/compare configurations accordingly:

- **🧪 Test-Mode**: Direct access to local `prometheus-stack-test` container  
- **🏠 Addon-Mode**: SSH access to Home Assistant addon container
- **🤖 Auto-Detection**: No manual configuration - tools detect the environment automatically

## 📁 Tool Overview

| Script                      | Purpose                                                | Works In   |
| --------------------------- | ------------------------------------------------------ | ---------- |
| **`s1_quick-ssh-test.sh`**  | Test container access and verify file availability     | Both modes |
| **`s2_extract-configs.sh`** | Extract ALL configuration files from running container | Both modes |
| **`s3_compare-configs.sh`** | Compare extracted files with git repository            | Both modes |
| **`s4_sync-to-repo.sh`**    | Automatically sync changes to git repository           | Both modes |

## 🚀 Quick Start

### For Development (Test-Mode)

```bash
# 1. Start your test container first
cd .. && ./test/build.sh

# 2. Use the sync tools (auto-detects Test-Mode)
cd sync-tools
./s1_quick-ssh-test.sh      # ✅ Tests container access
./s2_extract-configs.sh     # ✅ Extracts configurations
./s3_compare-configs.sh     # ✅ Compares with git repo
./s4_sync-to-repo.sh        # ✅ Automatically syncs changes to repository
```

### For Home Assistant (Addon-Mode)

```bash
# Tools automatically detect Addon-Mode when no test container found
./s1_quick-ssh-test.sh      # ✅ Tests SSH to homeassistant.local
./s2_extract-configs.sh     # ✅ Extracts via SSH from HA addon  
./s3_compare-configs.sh     # ✅ Compares with git repo
./s4_sync-to-repo.sh        # ✅ Automatically syncs changes to repository
```

## 🔍 Detailed Tool Explanations

### 1. `s1_quick-ssh-test.sh` - Environment Testing

**Purpose**: Verify that the tools can access your Prometheus Stack container and check what configuration files are available.

**What it does**:

- 🔍 **Auto-detects environment** (test vs addon mode)
- 🐳 **Lists running containers** matching the expected name
- 📊 **Tests file access** for all major config files:
  - Grafana dashboards (*.json)
  - Prometheus config (prometheus.yml)
  - Grafana settings (grafana.ini)
  - Blackbox exporter (blackbox.yml)
  - Alertmanager config (alertmanager.yml)
- 📡 **Tests API endpoints** (Grafana health check)
- 📁 **Shows relevant directories** for each mode

**Output Example**:

```text
🧪 Test mode detected (local container)
🔍 Testing access to prometheus configuration files...
Target: localhost (container filter: prometheus-stack-test)
========================================================
🐳 1. Container Status:
NAMES                   STATUS          PORTS
prometheus-stack-test   Up 2 minutes    0.0.0.0:8080->8080/tcp, ...

✅ Container found: a1b2c3d4e5f6
  📊 Dashboards: 8 dashboard files found
  🎯 Prometheus: prometheus.yml accessible
  📊 Grafana: grafana.ini accessible
  🔎 Blackbox: blackbox.yml accessible
  🚨 Alertmanager: alertmanager.yml accessible
✅ Grafana API accessible
```

### 2. `s2_extract-configs.sh` - Configuration Extraction

**Purpose**: Extract ALL configuration files from the running container to your local machine for inspection and comparison.

**What it extracts**:

- 📊 **Grafana Dashboards**: All JSON dashboard files from `/etc/grafana/provisioning/dashboards/`
- 🎯 **Prometheus Config**: `prometheus.yml` and any alert rules from `/etc/prometheus/`
- 📊 **Grafana Settings**: `grafana.ini` and provisioning configs from `/etc/grafana/`
- 🔎 **Blackbox Config**: `blackbox.yml` from `/etc/blackbox_exporter/`
- 🚨 **Alertmanager Config**: `alertmanager.yml` from `/etc/alertmanager/` (dynamically generated)

**Process**:

1. **Container Detection**: Finds the appropriate container
2. **Temp Directory**: Creates `/tmp/extracted-configs/` on target host
3. **Docker Copy**: Uses `docker cp` to extract files from container
4. **Local Copy**: Copies files to `./ssh-extracted-configs/` directory
5. **Cleanup**: Removes temporary files

**Output Structure**:

```text
ssh-extracted-configs/
├── dashboards/dashboards/     # Grafana dashboard JSON files
├── prometheus/                # prometheus.yml and rules/
├── grafana/                   # grafana.ini and provisioning/
├── blackbox/                  # blackbox.yml
└── alerting/                  # alertmanager.yml (dynamic)
```

### 3. `s3_compare-configs.sh` - Configuration Comparison

**Purpose**: Compare extracted configurations with your git repository to identify what has changed and needs syncing.

**Comparison Logic**:

- ✅ **IDENTICAL**: Files match exactly - no action needed
- 🔄 **DIFFERENT**: Files differ - shows `diff` command to review changes
- 🆕 **NEW FILE**: Found in container but not in git - consider adding
- 📋 **DYNAMIC**: Generated configs (like alertmanager.yml) - special handling

**What it compares**:

- **Dashboard files**: Compares with both `./dashboards/` (source) and `./prometheus-stack/rootfs/etc/grafana/provisioning/dashboards/` (runtime)
- **Static configs**: Compares source files (`./prometheus-stack/prometheus.yml`) with extracted versions
- **Runtime configs**: Compares container versions with extracted files
- **Generated configs**: Special handling for dynamically created files

**Output Example**:

```text
🔸 Dashboard Files:
   ✅ Dashboard: 01-overview.json - IDENTICAL
   🔄 Dashboard: 02-home-assistant.json - DIFFERENT
      📋 Run: diff ./dashboards/02-home-assistant.json ./ssh-extracted-configs/dashboards/dashboards/02-home-assistant.json

🔸 Prometheus Configuration:
   ✅ prometheus.yml (source) - IDENTICAL
   prometheus.yml (runtime) - DIFFERENT
      📋 Run: diff ./prometheus-stack/rootfs/etc/prometheus/prometheus.yml ./ssh-extracted-configs/prometheus/prometheus.yml
```

### 4. `s4_sync-to-repo.sh` - Automatic Repository Sync

**Purpose**: **Automatically copy changes from the running instance to your git repository** - completing the sync workflow.

**What it does**:

- 🔄 **Automatic copying**: Copies changed files from `./ssh-extracted-configs/` to appropriate repository locations
- 📦 **Smart backups**: Creates timestamped backups before overwriting existing files
- 🎯 **Component-aware**: Handles different file types correctly:
  - **Dashboards**: Copies to both `./dashboards/` (source) and `./prometheus-stack/rootfs/etc/grafana/provisioning/dashboards/` (runtime)
  - **Prometheus**: Copies to both source and runtime locations
  - **Grafana**: Copies to both source and runtime locations  
  - **Blackbox**: Copies to both source and runtime locations
  - **Dynamic configs**: Provides guidance for alertmanager.yml (generated from options.json)

**Safety Features**:

- ✅ **Backup creation**: All existing files are backed up before overwriting
- ✅ **Directory creation**: Automatically creates missing directories
- ✅ **Error handling**: Stops on errors and provides clear feedback
- ✅ **Validation**: Checks prerequisites before starting

**Output Example**:

```text
🔄 Automatic Sync Tool - Copying changes from running instance to repository
==================================================================
🔍 Starting automatic sync process...
📁 Extracted files: ./ssh-extracted-configs/
📁 Target repository: ../
📦 Backups will be saved to: ./sync-backups/20241201_143022

📊 Syncing Dashboard Files...
   🔄 Dashboard: 02-home-assistant.json - DIFFERENT (will sync)
   📦 Backed up: ./dashboards/02-home-assistant.json → ./dashboards/02-home-assistant.json.backup.20241201_143022
   ✅ Synced: ./ssh-extracted-configs/dashboards/dashboards/02-home-assistant.json → ./dashboards/02-home-assistant.json
   ✅ Synced: ./ssh-extracted-configs/dashboards/dashboards/02-home-assistant.json → ./prometheus-stack/rootfs/etc/grafana/provisioning/dashboards/02-home-assistant.json
   📊 Synced 2 dashboard operations

🎯 Syncing Prometheus Configuration...
   ✅ prometheus.yml (source) - IDENTICAL (no sync needed)
   🔄 prometheus.yml (runtime) - DIFFERENT (will sync)
   📦 Backed up: ./prometheus-stack/rootfs/etc/prometheus/prometheus.yml → ./prometheus-stack/rootfs/etc/prometheus/prometheus.yml.backup.20241201_143022
   ✅ Synced: ./ssh-extracted-configs/prometheus/prometheus.yml → ./prometheus-stack/rootfs/etc/prometheus/prometheus.yml
   🎯 Synced 1 prometheus operations

✅ Sync process completed!
📊 Components processed: 2

📋 Sync Summary:
================
✅ Sync completed successfully!

📁 Files synced to:
   • Source files: ./dashboards/, ./prometheus-stack/
   • Runtime files: ./prometheus-stack/rootfs/etc/

📦 Backups created:
   • Check for .backup.* files in the repository

🚨 Next Steps:
   1. Review the changes: git diff
   2. Test the changes: cd .. && ./test/build.sh
   3. Commit when satisfied: git add . && git commit -m 'Sync changes from running instance'
   4. Clean up backups if everything works: find . -name '*.backup.*' -delete
```

## 🎯 Use Cases & Workflows

### Development Workflow (Test-Mode)

**Scenario**: You're developing locally and want to sync changes between your test container and git repository.

```bash
# 1. Start development container
./test/build.sh

# 2. Make changes to configs through various methods:
#    - Edit test-data/options.json (affects alertmanager.yml, karma.yml)  
#    - Access Grafana UI at http://localhost:3000 (modify dashboards)
#    - Access Prometheus UI at http://localhost:9090 (add alert rules)

# 3. Extract current state
cd sync-tools
./s2_extract-configs.sh

# 4. See what changed
./s3_compare-configs.sh

# 5. Automatically sync changes to git repository
./s4_sync-to-repo.sh

# 6. Test changes
cd .. && ./test/build.sh  # Rebuild with new configs
```

### Production Sync Workflow (Addon-Mode)

**Scenario**: You've customized your Home Assistant addon and want to save changes to git.

```bash
# 1. Make changes in Home Assistant:
#    - Customize Grafana dashboards via HA Grafana UI
#    - Modify addon config via HA addon configuration tab
#    - Add/modify Prometheus targets or alert rules

# 2. Extract current addon state
./s2_extract-configs.sh    # Uses SSH to homeassistant.local

# 3. Compare with your git repository
./s3_compare-configs.sh

# 4. Automatically sync changes to git repository
./s4_sync-to-repo.sh

# 5. Test and deploy
#    - Test locally: ./test/build.sh
#    - Commit changes to git
#    - Update addon in Home Assistant
```

### Configuration Debugging

**Scenario**: Something isn't working and you want to see the actual runtime configuration.

```bash
# Quick health check
./s1_quick-ssh-test.sh

# Extract current configs to inspect
./s2_extract-configs.sh

# Check what's actually running vs what's in git
./s3_compare-configs.sh

# Optionally sync changes to repository
./s4_sync-to-repo.sh

# Manually inspect specific files
cat ./ssh-extracted-configs/alerting/alertmanager.yml  # See generated config
cat ./ssh-extracted-configs/prometheus/prometheus.yml  # See runtime config
```

## 🔧 Environment Detection Details

The tools use this logic to determine your environment:

```bash
if docker ps --filter 'name=prometheus-stack-test' | grep -q prometheus-stack-test; then
    # 🧪 TEST MODE
    # - Target: localhost
    # - Container: prometheus-stack-test  
    # - Method: Direct docker commands
    # - Copy: Local filesystem operations
else
    # 🏠 ADDON MODE  
    # - Target: homeassistant.local
    # - Container: prometheus (addon container name)
    # - Method: SSH to root@homeassistant.local
    # - Copy: scp from remote host
fi
```

## ⚙️ Requirements

### For Test Mode (Local Development)

- ✅ Docker installed and running
- ✅ Test container running (`./test/build.sh`)
- ✅ Container named `prometheus-stack-test` (configurable via .env)

### For Addon Mode (Home Assistant)

- ✅ SSH addon enabled in Home Assistant
- ✅ SSH access to Home Assistant host (configurable via .env)
- ✅ Prometheus Stack addon installed and running
- ✅ Network connectivity to Home Assistant

### Both Modes

- ✅ Bash shell environment
- ✅ Standard Unix tools: `docker`, `cp`, `find`, `diff`
- ✅ For remote: `ssh`, `scp`

## 🔧 Configuration

The sync tools use a `.env` file for configuration. This allows you to customize connection settings, container names, and sync behavior without modifying the scripts.

### Setup Configuration

1. **Copy the example file:**

   ```bash
   cp .env.example .env
   ```

2. **Edit the configuration:**

   ```bash
   nano .env
   ```

### Configuration Options

| Setting | Default | Description |
|---------|---------|-------------|
| `HA_HOSTNAME` | `homeassistant.local` | Home Assistant hostname/IP |
| `HA_SSH_USER` | `root` | SSH username |
| `HA_SSH_PORT` | `22` | SSH port |
| `HA_SSH_KEY` | `~/.ssh/id_rsa` | SSH private key path |
| `HA_SSH_PASSWORD` | (empty) | SSH password (if no key) |
| `LOCAL_CONTAINER_NAME` | `prometheus-stack-test` | Local test container name |
| `REMOTE_CONTAINER_NAME` | `prometheus` | Remote addon container name |
| `SYNC_BACKUP_DIR` | `./sync-backups` | Backup directory |
| `EXTRACTED_DIR` | `./ssh-extracted-configs` | Extracted files directory |
| `VERBOSE` | `false` | Enable verbose logging |
| `DRY_RUN` | `false` | Show what would be done without making changes |

### Example .env File

```bash
# Home Assistant Connection
HA_HOSTNAME=192.168.1.100
HA_SSH_USER=root
HA_SSH_PORT=22222
HA_SSH_KEY=~/.ssh/ha_key

# Container Names
LOCAL_CONTAINER_NAME=my-prometheus-test
REMOTE_CONTAINER_NAME=my-prometheus-addon

# Sync Settings
SYNC_BACKUP_DIR=./my-backups
VERBOSE=true
```

## 🚨 Troubleshooting

### "No prometheus container found"

- **Test Mode**: Run `./test/build.sh` first
- **Addon Mode**: Check addon is running in Home Assistant
- **Both**: Verify with `docker ps` (locally) or SSH access (remotely)

### "SSH connection failed"

- Check SSH addon is enabled in Home Assistant
- Verify hostname: try `ssh root@homeassistant.local`
- Check network connectivity to Home Assistant
- Try using IP address instead of hostname
- Check your `.env` configuration (HA_HOSTNAME, HA_SSH_USER, HA_SSH_PORT)
- Verify SSH key path and permissions in `.env`
- Test SSH connection manually: `ssh -p PORT USER@HOSTNAME`

### "No extracted files found"

- Run `./s2_extract-configs.sh` before `./s3_compare-configs.sh`
- Check for error messages in extraction output
- Verify container has required config files

### "Permission denied"

- **Test Mode**: Check Docker daemon is running and accessible
- **Addon Mode**: Verify SSH user has docker access (should be `root`)

### "Configuration not found"

- Copy `.env.example` to `.env`: `cp .env.example .env`
- Edit `.env` with your settings
- Ensure `.env` file is in the `addon-sync-tools` directory

## 💡 Advanced Usage

### Custom SSH Configuration

If your Home Assistant isn't at `homeassistant.local`, you can modify the scripts:

```bash
# Edit the scripts to change the default
sed -i 's/homeassistant.local/YOUR_HA_IP/g' *.sh
```

### Selective Extraction

To extract only specific components, modify `s2_extract-configs.sh` and comment out unwanted sections.

### Automated Workflows

These tools are designed to be scriptable. Example automation:

```bash
#!/bin/bash
# Auto-sync script
cd sync-tools
./s2_extract-configs.sh
if ./s3_compare-configs.sh | grep -q "DIFFERENT"; then
    echo "Changes detected - syncing to repository..."
    ./s4_sync-to-repo.sh
    echo "✅ Sync completed! Review changes with: git diff"
else
    echo "No changes detected"
fi
```

## 🤝 Contributing

If you find bugs or want to improve these tools:

1. Test changes in both modes (test and addon)
2. Ensure auto-detection still works
3. Update this README if you change functionality
4. Test with different Home Assistant setups
