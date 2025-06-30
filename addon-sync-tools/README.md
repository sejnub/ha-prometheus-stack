# Addon Configuration Sync Tools

Tools for syncing **ALL configuration changes** from **Home Assistant Addon-Mode** back to the git repository.

## 📁 Files

- **`quick-ssh-test.sh`** - Test SSH access and verify what files are accessible
- **`extract-configs.sh`** - Extract ALL configuration files from running addon container
- **`compare-configs.sh`** - Compare extracted files with git repository

## 🚀 Quick Start

```bash
# 1. Test SSH access to addon container
./quick-ssh-test.sh

# 2. Extract ALL current configuration files
./extract-configs.sh

# 3. Compare with git repository
./compare-configs.sh
```

## 🎯 Use Case

**Problem**: You customize your monitoring setup by making changes to:
- **Prometheus configuration** (prometheus.yml, alert rules)
- **Grafana dashboards** and settings (grafana.ini)
- **Blackbox exporter probes** (blackbox.yml)
- **Alertmanager configuration** (alertmanager.yml)
- **Other component settings**

But need to sync those changes back to your git repository for version control and deployment.

**Solution**: This prometheus-stack addon stores all files inside the Docker container (not in `/addon_configs/`). These tools use SSH to extract ALL configuration files from the running container.

## 📋 Workflow

1. **Make changes** in Home Assistant:
   - Grafana dashboards via UI
   - Prometheus config via addon config editor
   - Alert rules via Prometheus UI
   - Blackbox probes via config files
2. **Extract files** using `extract-configs.sh`
3. **Compare changes** using `compare-configs.sh`
4. **Manually copy** desired changes to git repository
5. **Test and commit** using standard git workflow

## 💡 Additional Options

The scripts include built-in help and error messages. For advanced usage:
- Check script comments for customization options
- Modify `HA_IP` and `HA_USER` variables if needed
- Scripts are designed to be self-contained and easy to understand

## ⚙️ Requirements

- SSH addon enabled in Home Assistant
- SSH access to `root@homeassistant.local` (or your HA IP)
- Running prometheus-stack addon container 