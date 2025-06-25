# VS Code Integration Guide

This add-on now includes a full-featured VS Code editor powered by code-server, allowing you to edit configuration files, write scripts, and develop directly in your browser.

## Table of Contents

- [Table of Contents](#table-of-contents)
- [1. Overview](#1-overview)
- [2. Configuration](#2-configuration)
- [3. Access Methods](#3-access-methods)
- [4. Features](#4-features)
- [5. Usage](#5-usage)
- [6. Extensions](#6-extensions)
- [7. Troubleshooting](#7-troubleshooting)
- [8. Security](#8-security)

## 1. Overview

### What is VS Code in this Add-on?

The Prometheus Stack add-on now includes **code-server**, which is VS Code running in a browser. This gives you:

- **Full VS Code Experience**: Complete editor with IntelliSense, debugging, and extensions
- **Configuration Editing**: Edit all Prometheus Stack configuration files directly
- **Script Development**: Write and test monitoring scripts, automation, and utilities
- **Extension Support**: Install and use VS Code extensions for enhanced functionality
- **Multi-language Support**: JavaScript, Python, YAML, JSON, and many more languages

### Components

- **Code-Server**: VS Code Server v4.19.1
- **Port**: 8443 (direct access) or `/vscode/` (ingress)
- **Authentication**: Password-based (configurable)
- **Workspace**: `/config` (default, configurable)
- **Extensions**: Persistent storage for installed extensions

## 2. Configuration

### Add-on Configuration Options

```yaml
# Enable or disable VS Code
enable_vscode: false

# Password for VS Code access (required if enabled)
vscode_password: ""

# Workspace directory (default: /config)
vscode_workspace: "/config"
```

### Configuration Examples

#### Basic Setup
```yaml
enable_vscode: true
vscode_password: "mypassword123"
vscode_workspace: "/config"
```

#### Advanced Setup
```yaml
enable_vscode: true
vscode_password: "secure_password_here"
vscode_workspace: "/data"  # Access to all add-on data
```

## 3. Access Methods

### Method 1: Home Assistant Ingress (Recommended)
1. Open the Prometheus Stack add-on in Home Assistant
2. Navigate to the main dashboard
3. Click on "VS Code Editor" link
4. Enter your configured password
5. Start coding!

**URL**: `http://your-ha-instance/ingress/prometheus-stack/vscode/`

### Method 2: Direct Port Access
1. Enable port 8443 in the add-on configuration
2. Access directly via: `http://your-ha-instance:8443`
3. Enter your configured password

**URL**: `http://your-ha-instance:8443`

### Method 3: From Main Dashboard
1. Open the Prometheus Stack add-on
2. Click on the VS Code card in the service grid
3. Choose either "VS Code Editor" (ingress) or "Direct VS Code"

## 4. Features

### Core VS Code Features
- **IntelliSense**: Code completion and suggestions
- **Syntax Highlighting**: Support for 100+ programming languages
- **Integrated Terminal**: Full terminal access within VS Code
- **Git Integration**: Version control directly in the editor
- **Debugging**: Debug your applications and scripts
- **Extensions**: Install and use VS Code extensions

### Prometheus Stack Specific Features
- **Configuration Editing**: Edit all add-on configuration files
- **YAML Support**: Full YAML syntax highlighting and validation
- **JSON Support**: JSON editing with validation
- **File Explorer**: Browse and edit files in the workspace
- **Search**: Find and replace across all files
- **Multi-file Editing**: Edit multiple files simultaneously

### Supported File Types
- **Configuration Files**: `.yml`, `.yaml`, `.json`, `.conf`
- **Scripts**: `.sh`, `.py`, `.js`, `.ts`
- **Documentation**: `.md`, `.txt`
- **Data Files**: `.csv`, `.log`
- **And many more...**

## 5. Usage

### Getting Started

1. **Enable VS Code**:
   - Go to Prometheus Stack add-on configuration
   - Set `enable_vscode: true`
   - Set a secure password
   - Save and restart the add-on

2. **Access VS Code**:
   - Open the add-on dashboard
   - Click on the VS Code card
   - Choose your preferred access method
   - Enter your password

3. **Start Editing**:
   - Open the file explorer (Ctrl+Shift+E)
   - Navigate to your configuration files
   - Start editing with full VS Code features

### Common Workflows

#### Editing Prometheus Configuration
1. Open VS Code
2. Navigate to `/config/prometheus/prometheus.yml`
3. Edit your scrape configurations, alert rules, etc.
4. Save the file
5. Restart the add-on to apply changes

#### Creating Custom Scripts
1. Open VS Code
2. Create a new file in your workspace
3. Write your monitoring or automation script
4. Use the integrated terminal to test your script
5. Save and use your script

#### Managing Extensions
1. Open VS Code
2. Go to Extensions (Ctrl+Shift+X)
3. Search for and install desired extensions
4. Extensions persist across add-on restarts

## 6. Extensions

### Recommended Extensions

#### For Configuration Management
- **YAML**: YAML language support
- **JSON Tools**: JSON formatting and validation
- **TOML**: TOML file support
- **Docker**: Docker file support

#### For Development
- **Python**: Python language support
- **JavaScript**: JavaScript/TypeScript support
- **Shell Script**: Shell script syntax highlighting
- **GitLens**: Enhanced Git capabilities

#### For Monitoring
- **Prometheus**: Prometheus query language support
- **Grafana**: Grafana dashboard support
- **Docker**: Container management

### Installing Extensions

1. Open VS Code
2. Press `Ctrl+Shift+X` (or `Cmd+Shift+X` on Mac)
3. Search for the extension you want
4. Click "Install"
5. Extensions are stored persistently in `/opt/code-server/extensions`

## 7. Troubleshooting

### Common Issues

#### VS Code Won't Start
- **Check Configuration**: Ensure `enable_vscode: true` is set
- **Check Password**: Ensure a password is configured
- **Check Logs**: View add-on logs for error messages
- **Check Port**: Ensure port 8443 is available (if using direct access)

#### Can't Access VS Code
- **Ingress Issues**: Try direct port access instead
- **Password Issues**: Reset the password in configuration
- **Network Issues**: Check Home Assistant network settings

#### Extensions Not Working
- **Restart VS Code**: Close and reopen the browser tab
- **Check Permissions**: Ensure the workspace directory is writable
- **Check Storage**: Ensure sufficient disk space for extensions

#### Performance Issues
- **Close Unused Tabs**: Close unnecessary files and tabs
- **Disable Heavy Extensions**: Disable resource-intensive extensions
- **Check System Resources**: Monitor CPU and memory usage

### Debug Mode

Enable debug mode by checking the add-on logs:

```bash
# View add-on logs
docker logs prometheus-stack

# View VS Code specific logs
docker exec prometheus-stack journalctl -u code-server
```

## 8. Security

### Security Features

- **Password Authentication**: Required for all VS Code access
- **Isolated Environment**: VS Code runs in container isolation
- **Workspace Restrictions**: Limited to configured workspace directory
- **No External Access**: VS Code only accessible through configured methods

### Best Practices

1. **Use Strong Passwords**: Choose a secure, unique password
2. **Limit Access**: Only enable VS Code when needed
3. **Regular Updates**: Keep the add-on updated for security patches
4. **Monitor Usage**: Check logs for unusual activity
5. **Backup Configurations**: Regularly backup your configuration files

### Network Security

- **Ingress Only**: VS Code accessible only through Home Assistant ingress
- **Local Network**: Direct access limited to local network
- **No External Exposure**: VS Code not exposed to the internet by default

## Additional Resources

- [Code-Server Documentation](https://coder.com/docs/code-server)
- [VS Code Documentation](https://code.visualstudio.com/docs)
- [VS Code Extensions Marketplace](https://marketplace.visualstudio.com/)
- [Prometheus Configuration](https://prometheus.io/docs/prometheus/latest/configuration/)
- [Home Assistant Add-ons](https://developers.home-assistant.io/docs/add-ons/)

---

**Note**: VS Code integration is designed to enhance your Prometheus Stack experience by providing a powerful development environment. Use it responsibly and ensure your configurations are properly backed up. 