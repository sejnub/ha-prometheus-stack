# Configuration Editing Guide

This add-on now supports editing all configuration files after startup through the VS Code add-on or file editor.

## 📁 **Available Configuration Files**

All configuration files are now stored in persistent locations and can be edited:

### **In VS Code Add-on, you'll see:**
```
config/
├── prometheus/
│   └── prometheus.yml          # Prometheus configuration
├── alertmanager/
│   └── alertmanager.yml        # Alertmanager configuration
├── blackbox_exporter/
│   └── blackbox.yml           # Blackbox Exporter configuration
├── karma/
│   └── karma.yml              # Karma UI configuration
├── nginx/
│   └── nginx.conf             # NGINX configuration
└── options.json               # Add-on options (read-only)
```

## 🔧 **How to Edit Configurations**

### **Method 1: VS Code Add-on (Recommended)**
1. Open VS Code add-on in Home Assistant
2. Navigate to the `config/` folder
3. Edit any configuration file directly
4. Save the file
5. Restart the add-on to apply changes

### **Method 2: File Editor Add-on**
1. Install File Editor add-on in Home Assistant
2. Navigate to `/addons/local/prometheus-stack/config/`
3. Edit configuration files
4. Restart the add-on

### **Method 3: SSH + Text Editor**
1. Enable SSH add-on
2. Connect via SSH
3. Edit files in `/addons/local/prometheus-stack/config/`
4. Restart the add-on

## 📝 **Configuration File Details**

### **prometheus.yml**
- **Purpose**: Prometheus server configuration
- **What you can edit**:
  - Scrape intervals
  - Target configurations
  - Alert rules
  - Recording rules
  - Global settings

### **alertmanager.yml**
- **Purpose**: Alert routing and notification configuration
- **What you can edit**:
  - Email settings
  - Notification receivers
  - Alert routing rules
  - Timeout settings

### **blackbox.yml**
- **Purpose**: Blackbox Exporter probe configuration
- **What you can edit**:
  - HTTP/TCP probe settings
  - SSL certificate checks
  - Timeout configurations
  - Custom modules

### **karma.yml**
- **Purpose**: Karma UI configuration
- **What you can edit**:
  - Alertmanager connections
  - UI settings
  - Label configurations
  - Authentication settings

### **nginx.conf**
- **Purpose**: NGINX reverse proxy configuration
- **What you can edit**:
  - Ingress routing rules
  - SSL settings
  - Proxy configurations
  - Custom headers

## ⚠️ **Important Notes**

### **Before Making Changes:**
1. **Backup your configuration** - Copy files before editing
2. **Test syntax** - Validate YAML syntax before restarting
3. **Check logs** - Monitor logs after restart for errors

### **After Making Changes:**
1. **Restart the add-on** - Changes require restart to take effect
2. **Check service health** - Verify all services start correctly
3. **Monitor logs** - Look for configuration errors

### **Validation:**
- **Prometheus**: Uses `promtool check config`
- **Alertmanager**: Uses `amtool check-config`
- **Blackbox**: Uses `--config.check` flag
- **NGINX**: Uses `nginx -t`

## 🔄 **Configuration Reload**

### **Automatic Reload (Some Services):**
- **Prometheus**: Supports hot reload via API
- **Alertmanager**: Supports hot reload via API
- **NGINX**: Requires restart for config changes

### **Manual Reload:**
```bash
# Prometheus hot reload
curl -X POST http://localhost:9090/-/reload

# Alertmanager hot reload
curl -X POST http://localhost:9093/-/reload
```

## 💡 **Pro Tips**

1. **Start Small**: Make incremental changes and test each one
2. **Use Comments**: Add comments to your configs for clarity
3. **Version Control**: Consider backing up configs to git
4. **Test Mode**: Use the test scripts to validate configurations
5. **Documentation**: Refer to official docs for each service

## 🆘 **Troubleshooting**

### **Common Issues:**
- **YAML Syntax Errors**: Use online YAML validators
- **Service Won't Start**: Check logs for configuration errors
- **Changes Not Applied**: Ensure you restarted the add-on
- **Permission Issues**: Check file permissions in config directory

### **Recovery:**
- **Restore from Backup**: Copy backed up configuration files
- **Reset to Defaults**: Delete config files and restart (they'll be regenerated)
- **Check Logs**: Use `docker logs` to see detailed error messages

## 📚 **Additional Resources**

- [Prometheus Configuration](https://prometheus.io/docs/prometheus/latest/configuration/)
- [Alertmanager Configuration](https://prometheus.io/docs/alerting/latest/configuration/)
- [Blackbox Exporter Configuration](https://github.com/prometheus/blackbox_exporter/blob/master/CONFIGURATION.md)
- [Karma Configuration](https://github.com/prymitive/karma/blob/main/docs/CONFIGURATION.md)
- [NGINX Configuration](https://nginx.org/en/docs/) 