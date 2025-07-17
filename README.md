# InfluxDB Stack Add-on for Home Assistant

A comprehensive time-series monitoring stack for Home Assistant that includes InfluxDB 2.x, Grafana with built-in Alerting, and VS Code in a single add-on.

- [1. What is this?](#1-what-is-this)
- [2. Key Features](#2-key-features)
- [3. Installation](#3-installation)
  - [3.1. Prerequisites](#31-prerequisites)
  - [3.2. Steps](#32-steps)
- [4. Configuration](#4-configuration)
  - [4.1. Add-on Configuration](#41-add-on-configuration)
  - [4.2. Option Descriptions](#42-option-descriptions)
- [5. Access](#5-access)
- [6. Monitoring](#6-monitoring)
  - [6.1. Home Assistant Metrics](#61-home-assistant-metrics)
  - [6.2. Time Series Analytics](#62-time-series-analytics)
- [7. Alerting](#7-alerting)
  - [7.1. Grafana Alerting](#71-grafana-alerting)
  - [7.2. Custom Alerts](#72-custom-alerts)
- [8. VS Code Integration](#8-vs-code-integration)
  - [Quick Start](#quick-start)
- [9. Development and Testing](#9-development-and-testing)
- [10. Support](#10-support)
- [11. License](#11-license)

## 1. What is this?

This add-on provides a complete time-series monitoring solution for your Home Assistant environment:

- **InfluxDB 2.x**: Purpose-built time-series database for metrics, events, and analytics
- **Grafana**: Beautiful dashboards and advanced visualization with built-in alerting
- **VS Code**: Full-featured code editor for configuration editing and development

## 2. Key Features

- **Multi-architecture**: Works on `amd64`, `arm64`, and `armv7`
- **Modern Time-Series Database**: InfluxDB 2.x with high performance and scalability
- **Integrated Alerting**: Grafana's built-in alerting system replaces traditional Alertmanager
- **Ingress Support**: Access all UIs directly through Home Assistant
- **Dynamic Config**: Automatic configuration from add-on settings
- **Data Persistence**: Survives add-on updates and restarts
- **HA Integration**: Seamless Home Assistant metrics collection
- **Pre-built Dashboards**: Ready-to-use Grafana dashboards
- **VS Code Integration**: Full-featured code editor with extensions support

## 3. Installation

### 3.1. Prerequisites

- Home Assistant (Supervisor or Core)
- Add-on store access

### 3.2. Steps

1. In Home Assistant, go to **Settings** → **Add-ons** → **Add-on Store**
2. Click the three dots in the top right and select **Repositories**
3. Add this repository URL: `https://github.com/sejnub/ha-influxdb-stack`
4. Find "InfluxDB Stack" in the add-on store
5. Click **Install**

## 4. Configuration

### 4.1. Add-on Configuration

```yaml
influxdb_org: "my-org"
influxdb_bucket: "my-bucket"
influxdb_username: "admin"
influxdb_password: "admin123"
influxdb_token: ""
home_assistant_url: "http://supervisor/core"
home_assistant_token: "your_long_lived_token"
enable_vscode: false
vscode_password: ""
vscode_workspace: "/config"
grafana_admin_password: "admin"
```

### 4.2. Option Descriptions

- `influxdb_org`: InfluxDB organization name
- `influxdb_bucket`: Default bucket for storing data
- `influxdb_username`: InfluxDB admin username
- `influxdb_password`: InfluxDB admin password
- `influxdb_token`: InfluxDB API token (auto-generated if empty)
- `home_assistant_url`: URL of your Home Assistant instance
- `home_assistant_token`: Long-lived access token for Home Assistant
- `enable_vscode`: Enable or disable VS Code editor
- `vscode_password`: Password for VS Code access (required if enabled)
- `vscode_workspace`: Workspace directory for VS Code (default: `/config`)
- `grafana_admin_password`: Grafana admin password

## 5. Access

All services are accessible through Home Assistant's ingress feature:

- **InfluxDB UI**: Through Home Assistant Ingress (main interface)
- **Grafana**: Through `/grafana/` path for dashboards and alerting
- **VS Code**: Through `/vscode/` path (when enabled)

Direct port access is also available:
- **InfluxDB**: Port 8086
- **Grafana**: Port 3000

## 6. Monitoring

### 6.1. Home Assistant Metrics

The add-on automatically collects:

- System performance metrics
- Entity state information
- Automation execution data
- Integration status
- Historical time-series data

### 6.2. Time Series Analytics

InfluxDB 2.x provides:

- High-performance time-series queries
- Flux query language for advanced analytics
- Real-time data processing
- Efficient data compression
- Automatic data retention policies

## 7. Alerting

### 7.1. Grafana Alerting

Grafana's built-in alerting system provides:

- Unified alerting interface
- Multiple notification channels
- Alert rules and conditions
- Silence management
- Alert history and insights

### 7.2. Custom Alerts

Create custom alerts through:

- Grafana alert rules
- InfluxDB tasks and checks
- Custom notification channels

## 8. VS Code Integration

The add-on includes a full-featured VS Code editor powered by code-server, allowing you to:

- **Edit Configuration Files**: Modify all InfluxDB Stack configurations directly
- **Write Scripts**: Create and test monitoring scripts and automation
- **Install Extensions**: Use VS Code extensions for enhanced functionality
- **Multi-language Support**: JavaScript, Python, YAML, JSON, and many more

### Quick Start

1. Enable VS Code in the add-on configuration
2. Set a secure password
3. Access VS Code through the main dashboard
4. Start editing your configuration files

For detailed VS Code usage instructions, see [influxdb-stack/VSCODE_GUIDE.md](influxdb-stack/VSCODE_GUIDE.md).

## 9. Development and Testing

For development and testing instructions, see [test/README.md](test/README.md).

## 10. Support

- [Documentation](https://github.com/sejnub/ha-influxdb-stack/wiki)
- [Issue Tracker](https://github.com/sejnub/ha-influxdb-stack/issues)

## 11. License

MIT License - see [LICENSE](LICENSE) file for details
