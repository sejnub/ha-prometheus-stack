# Addon Configuration Sync Tools

**Intelligent tools for syncing configuration changes** between your development environment, local testing, and deployed Home Assistant addon. Works seamlessly in both **Test Mode** (local development) and **Addon Mode** (deployed Home Assistant).

## 🎯 What These Tools Do

The Prometheus Stack addon stores all configuration files inside Docker containers rather than in `/addon_configs/`. These tools automatically detect your environment and extract/compare configurations accordingly:

- **🧪 Test Mode**: Direct access to local `prometheus-stack-test` container  
- **🏠 Addon Mode**: SSH access to Home Assistant addon container
- **🤖 Auto-Detection**: No manual configuration - tools detect the environment automatically

## 📁 Tool Overview

| Script                   | Purpose                                                | Works In   |
| ------------------------ | ------------------------------------------------------ | ---------- |
| **`quick-ssh-test.sh`**  | Test container access and verify file availability     | Both modes |
| **`extract-configs.sh`** | Extract ALL configuration files from running container | Both modes |
| **`compare-configs.sh`** | Compare extracted files with git repository            | Both modes |

## 🚀 Quick Start

### For Local Testing (Test Mode)

```bash
# 1. Start your test container first
cd .. && ./test/build-test.sh

# 2. Use the sync tools (auto-detects test mode)
cd addon-sync-tools
./quick-ssh-test.sh      # ✅ Tests local container access
./extract-configs.sh     # ✅ Extracts from local container
./compare-configs.sh     # ✅ Compares with git repo
```

### For Home Assistant Addon (Addon Mode)

```bash
# Tools automatically detect remote mode when no local container found
./quick-ssh-test.sh      # ✅ Tests SSH to homeassistant.local
./extract-configs.sh     # ✅ Extracts via SSH from HA addon  
./compare-configs.sh     # ✅ Compares with git repo
```

## 🔍 Detailed Tool Explanations

### 1. `quick-ssh-test.sh` - Environment Testing

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

### 2. `extract-configs.sh` - Configuration Extraction

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

### 3. `compare-configs.sh` - Configuration Comparison

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
   🔄 prometheus.yml (runtime) - DIFFERENT
      📋 Run: diff ./prometheus-stack/rootfs/etc/prometheus/prometheus.yml ./ssh-extracted-configs/prometheus/prometheus.yml
```

## 🎯 Use Cases & Workflows

### Development Workflow (Test Mode)

**Scenario**: You're developing locally and want to sync changes between your test container and git repository.

```bash
# 1. Start development container
./test/build-test.sh

# 2. Make changes to configs through various methods:
#    - Edit test-data/options.json (affects alertmanager.yml, karma.yml)  
#    - Access Grafana UI at http://localhost:3000 (modify dashboards)
#    - Access Prometheus UI at http://localhost:9090 (add alert rules)

# 3. Extract current state
cd addon-sync-tools
./extract-configs.sh

# 4. See what changed
./compare-configs.sh

# 5. Sync desired changes back to git
# (manually copy files based on comparison output)

# 6. Test changes
cd .. && ./test/build-test.sh  # Rebuild with new configs
```

### Production Sync Workflow (Addon Mode)

**Scenario**: You've customized your Home Assistant addon and want to save changes to git.

```bash
# 1. Make changes in Home Assistant:
#    - Customize Grafana dashboards via HA Grafana UI
#    - Modify addon config via HA addon configuration tab
#    - Add/modify Prometheus targets or alert rules

# 2. Extract current addon state
./extract-configs.sh    # Uses SSH to homeassistant.local

# 3. Compare with your git repository
./compare-configs.sh

# 4. Review and sync changes
#    - Use suggested diff commands to review changes
#    - Manually copy desired changes to git repository
#    - Update both source files and runtime files as needed

# 5. Test and deploy
#    - Test locally: ./test/build-test.sh
#    - Commit changes to git
#    - Update addon in Home Assistant
```

### Configuration Debugging

**Scenario**: Something isn't working and you want to see the actual runtime configuration.

```bash
# Quick health check
./quick-ssh-test.sh

# Extract current configs to inspect
./extract-configs.sh

# Check what's actually running vs what's in git
./compare-configs.sh

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
- ✅ Test container running (`./test/build-test.sh`)
- ✅ Container named `prometheus-stack-test`

### For Addon Mode (Home Assistant)

- ✅ SSH addon enabled in Home Assistant
- ✅ SSH access to Home Assistant host (`root@homeassistant.local`)
- ✅ Prometheus Stack addon installed and running
- ✅ Network connectivity to Home Assistant

### Both Modes

- ✅ Bash shell environment
- ✅ Standard Unix tools: `docker`, `cp`, `find`, `diff`
- ✅ For remote: `ssh`, `scp`

## 🚨 Troubleshooting

### "No prometheus container found"

- **Test Mode**: Run `./test/build-test.sh` first
- **Addon Mode**: Check addon is running in Home Assistant
- **Both**: Verify with `docker ps` (locally) or SSH access (remotely)

### "SSH connection failed"

- Check SSH addon is enabled in Home Assistant
- Verify hostname: try `ssh root@homeassistant.local`
- Check network connectivity to Home Assistant
- Try using IP address instead of hostname

### "No extracted files found"

- Run `./extract-configs.sh` before `./compare-configs.sh`
- Check for error messages in extraction output
- Verify container has required config files

### "Permission denied"

- **Test Mode**: Check Docker daemon is running and accessible
- **Addon Mode**: Verify SSH user has docker access (should be `root`)

## 💡 Advanced Usage

### Custom SSH Configuration

If your Home Assistant isn't at `homeassistant.local`, you can modify the scripts:

```bash
# Edit the scripts to change the default
sed -i 's/homeassistant.local/YOUR_HA_IP/g' *.sh
```

### Selective Extraction

To extract only specific components, modify `extract-configs.sh` and comment out unwanted sections.

### Automated Workflows

These tools are designed to be scriptable. Example automation:

```bash
#!/bin/bash
# Auto-sync script
cd addon-sync-tools
./extract-configs.sh
if ./compare-configs.sh | grep -q "DIFFERENT"; then
    echo "Changes detected - manual review needed"
    ./compare-configs.sh  # Show details
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
