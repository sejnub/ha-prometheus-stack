# VS Code Integration Guide

This add-on now includes a full-featured VS Code editor powered by code-server, allowing you to edit configuration files, write scripts, and develop directly in your browser.

- [1. Overview](#1-overview)
  - [1.1. What is VS Code in this Add-on?](#11-what-is-vs-code-in-this-add-on)
  - [1.2. Components](#12-components)
- [2. Configuration](#2-configuration)
  - [2.1. Add-on Configuration Options](#21-add-on-configuration-options)
  - [2.2. Configuration Examples](#22-configuration-examples)
    - [2.2.1. Basic Setup](#221-basic-setup)
    - [2.2.2. Advanced Setup](#222-advanced-setup)
- [3. Access Methods](#3-access-methods)
  - [3.1. Method 1: Home Assistant Ingress (Recommended)](#31-method-1-home-assistant-ingress-recommended)
  - [3.2. Method 2: Direct Port Access](#32-method-2-direct-port-access)
  - [3.3. Method 3: From Main Dashboard](#33-method-3-from-main-dashboard)
- [4. Features](#4-features)
  - [4.1. Core VS Code Features](#41-core-vs-code-features)
  - [4.2. Prometheus Stack Specific Features](#42-prometheus-stack-specific-features)
  - [4.3. Supported File Types](#43-supported-file-types)
- [5. Usage](#5-usage)
  - [5.1. Getting Started](#51-getting-started)
  - [5.2. Common Workflows](#52-common-workflows)
    - [5.2.1. Editing Prometheus Configuration](#521-editing-prometheus-configuration)
    - [5.2.2. Creating Custom Scripts](#522-creating-custom-scripts)
    - [5.2.3. Managing Extensions](#523-managing-extensions)
- [6. Extensions](#6-extensions)
  - [6.1. Recommended Extensions](#61-recommended-extensions)
    - [6.1.1. For Configuration Management](#611-for-configuration-management)
    - [6.1.2. For Development](#612-for-development)
    - [6.1.3. For Monitoring](#613-for-monitoring)
  - [6.2. Installing Extensions](#62-installing-extensions)
- [7. Troubleshooting](#7-troubleshooting)
  - [7.1. Common Issues](#71-common-issues)
    - [7.1.1. VS Code Won't Start](#711-vs-code-wont-start)
    - [7.1.2. Can't Access VS Code](#712-cant-access-vs-code)
    - [7.1.3. Extensions Not Working](#713-extensions-not-working)
    - [7.1.4. Performance Issues](#714-performance-issues)
  - [7.2. Debug Mode](#72-debug-mode)
- [8. Security](#8-security)
  - [8.1. Security Features](#81-security-features)
  - [8.2. Best Practices](#82-best-practices)
  - [8.3. Network Security](#83-network-security)
- [9. Additional Resources](#9-additional-resources)

## 1. Overview

### 1.1. What is VS Code in this Add-on?

The Prometheus Stack add-on now includes **code-server**, which is VS Code running in a browser. This gives you:

- **Full VS Code Experience**: Complete editor with IntelliSense, debugging, and extensions
- **Configuration Editing**: Edit all Prometheus Stack configuration files directly
- **Script Development**: Write and test monitoring scripts, automation, and utilities
- **Extension Support**: Install and use VS Code extensions for enhanced functionality
- **Multi-language Support**: JavaScript, Python, YAML, JSON, and many more languages

### 1.2. Components

- **Code-Server**: VS Code Server v4.19.1
- **Port**: 8443 (direct access) or `/vscode/` (ingress)
- **Authentication**: Password-based (configurable)
- **Workspace**: `/config` (default, configurable)
- **Extensions**: Persistent storage for installed extensions

## 2. Configuration

### 2.1. Add-on Configuration Options

```yaml
# Enable or disable VS Code
enable_vscode: false

# Password for VS Code access (required if enabled)
vscode_password: ""

# Workspace directory (default: /config)
vscode_workspace: "/config"
```

### 2.2. Configuration Examples

#### 2.2.1. Basic Setup

```yaml
enable_vscode: true
vscode_password: "mypassword123"
vscode_workspace: "/config"
```

#### 2.2.2. Advanced Setup

```yaml
enable_vscode: true
vscode_password: "secure_password_here"
vscode_workspace: "/data"  # Access to all add-on data
```

## 3. Access Methods

### 3.1. Method 1: Home Assistant Ingress (Recommended)

1. Open the Prometheus Stack add-on in Home Assistant
2. Navigate to the main dashboard
3. Click on "VS Code Editor" link
4. Enter your configured password
5. Start coding!

**URL**: `http://your-ha-instance/ingress/prometheus-stack/vscode/`

### 3.2. Method 2: Direct Port Access

1. Enable port 8443 in the add-on configuration
2. Access directly via: `http://your-ha-instance:8443`
3. Enter your configured password

**URL**: `http://your-ha-instance:8443`

### 3.3. Method 3: From Main Dashboard

1. Open the Prometheus Stack add-on
2. Click on the VS Code card in the service grid
3. Choose either "VS Code Editor" (ingress) or "Direct VS Code"

## 4. Features

### 4.1. Core VS Code Features

- **IntelliSense**: Code completion and suggestions
- **Syntax Highlighting**: Support for 100+ programming languages
- **Integrated Terminal**: Full terminal access within VS Code
- **Git Integration**: Version control directly in the editor
- **Debugging**: Debug your applications and scripts
- **Extensions**: Install and use VS Code extensions

### 4.2. Prometheus Stack Specific Features

- **Configuration Editing**: Edit all add-on configuration files
- **YAML Support**: Full YAML syntax highlighting and validation
- **JSON Support**: JSON editing with validation
- **File Explorer**: Browse and edit files in the workspace
- **Search**: Find and replace across all files
- **Multi-file Editing**: Edit multiple files simultaneously

### 4.3. Supported File Types

- **Configuration Files**: `.yml`, `.yaml`, `.json`, `.conf`
- **Scripts**: `.sh`, `.py`, `.js`, `.ts`
- **Documentation**: `.md`, `.txt`
- **Data Files**: `.csv`, `.log`
- **And many more...**

## 5. Usage

### 5.1. Getting Started

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

### 5.2. Common Workflows

#### 5.2.1. Editing Prometheus Configuration

1. Open VS Code
2. Navigate to `/config/prometheus/prometheus.yml`
3. Edit your scrape configurations, alert rules, etc.
4. Save the file
5. Restart the add-on to apply changes

#### 5.2.2. Creating Custom Scripts

1. Open VS Code
2. Create a new file in your workspace
3. Write your monitoring or automation script
4. Use the integrated terminal to test your script
5. Save and use your script

#### 5.2.3. Managing Extensions

1. Open VS Code
2. Go to Extensions (Ctrl+Shift+X)
3. Search for and install desired extensions
4. Extensions persist across add-on restarts

## 6. Extensions

### 6.1. Recommended Extensions

#### 6.1.1. For Configuration Management

- **YAML**: YAML language support
- **JSON Tools**: JSON formatting and validation
- **TOML**: TOML file support
- **Docker**: Docker file support

#### 6.1.2. For Development

- **Python**: Python language support
- **JavaScript**: JavaScript/TypeScript support
- **Shell Script**: Shell script syntax highlighting
- **GitLens**: Enhanced Git capabilities

#### 6.1.3. For Monitoring

- **Prometheus**: Prometheus query language support
- **Grafana**: Grafana dashboard support
- **Docker**: Container management

### 6.2. Installing Extensions

1. Open VS Code
2. Press `Ctrl+Shift+X` (or `Cmd+Shift+X` on Mac)
3. Search for the extension you want
4. Click "Install"
5. Extensions are stored persistently in `/opt/code-server/extensions`

## 7. Troubleshooting

### 7.1. Common Issues

#### 7.1.1. VS Code Won't Start

- **Check Configuration**: Ensure `enable_vscode: true` is set
- **Check Password**: Ensure a password is configured
- **Check Logs**: View add-on logs for error messages
- **Check Port**: Ensure port 8443 is available (if using direct access)

#### 7.1.2. Can't Access VS Code

- **Ingress Issues**: Try direct port access instead
- **Password Issues**: Reset the password in configuration
- **Network Issues**: Check Home Assistant network settings

#### 7.1.3. Extensions Not Working

- **Restart VS Code**: Close and reopen the browser tab
- **Check Permissions**: Ensure the workspace directory is writable
- **Check Storage**: Ensure sufficient disk space for extensions

#### 7.1.4. Performance Issues

- **Close Unused Tabs**: Close unnecessary files and tabs
- **Disable Heavy Extensions**: Disable resource-intensive extensions
- **Check System Resources**: Monitor CPU and memory usage

### 7.2. Debug Mode

Enable debug mode by checking the add-on logs:

```bash
# View add-on logs
docker logs prometheus-stack

# View VS Code specific logs
docker exec prometheus-stack journalctl -u code-server
```

## 8. Security

### 8.1. Security Features

- **Password Authentication**: Required for all VS Code access
- **Isolated Environment**: VS Code runs in container isolation
- **Workspace Restrictions**: Limited to configured workspace directory
- **No External Access**: VS Code only accessible through configured methods

### 8.2. Best Practices

1. **Use Strong Passwords**: Choose a secure, unique password
2. **Limit Access**: Only enable VS Code when needed
3. **Regular Updates**: Keep the add-on updated for security patches
4. **Monitor Usage**: Check logs for unusual activity
5. **Backup Configurations**: Regularly backup your configuration files

### 8.3. Network Security

- **Ingress Only**: VS Code accessible only through Home Assistant ingress
- **Local Network**: Direct access limited to local network
- **No External Exposure**: VS Code not exposed to the internet by default

## 9. Additional Resources

- [Code-Server Documentation](https://coder.com/docs/code-server)
- [VS Code Documentation](https://code.visualstudio.com/docs)
- [VS Code Extensions Marketplace](https://marketplace.visualstudio.com/)
- [Prometheus Configuration](https://prometheus.io/docs/prometheus/latest/configuration/)
- [Home Assistant Add-ons](https://developers.home-assistant.io/docs/add-ons/)

---

**Note**: VS Code integration is designed to enhance your Prometheus Stack experience by providing a powerful development environment. Use it responsibly and ensure your configurations are properly backed up.
