# Grafana Dashboards for InfluxDB Stack

This directory contains pre-configured Grafana dashboards for monitoring your InfluxDB Stack add-on.

## 📋 Table of Contents

- [1. Dashboard Overview](#1-dashboard-overview)
  - [1.1. InfluxDB Stack Overview (`01-overview.json`)](#11-influxdb-stack-overview-01-overviewjson)
  - [1.2. Home Assistant Monitoring (`02-home-assistant.json`)](#12-home-assistant-monitoring-02-home-assistantjson)
  - [1.3. System Monitoring (`03-system.json`)](#13-system-monitoring-03-systemjson)
  - [1.4. InfluxDB Monitoring (`04-influxdb.json`)](#14-influxdb-monitoring-04-influxdbjson)
  - [1.5. Grafana Monitoring (`05-grafana.json`)](#15-grafana-monitoring-05-grafanajson)
- [2. Installation](#2-installation)
  - [2.1. Automatic Installation](#21-automatic-installation)
  - [2.2. Manual Installation](#22-manual-installation)
- [3. Usage](#3-usage)
  - [3.1. Viewing Dashboards](#31-viewing-dashboards)
  - [3.2. Customizing Dashboards](#32-customizing-dashboards)
- [4. Data Source Configuration](#4-data-source-configuration)
- [5. Troubleshooting](#5-troubleshooting)
  - [5.1. Common Issues](#51-common-issues)
  - [5.2. Metric Requirements](#52-metric-requirements)
- [6. Customization](#6-customization)
- [7. Support](#7-support)
- [8. License](#8-license)

## 1. Dashboard Overview

### 1.1. InfluxDB Stack Overview (`01-overview.json`)

- **Purpose**: High-level overview of the entire InfluxDB Stack
- **Key Metrics**:
  - Service status (InfluxDB, Grafana, VS Code, NGINX)
  - System resource usage (CPU, Memory, Disk)
  - Network activity and connections
  - Data ingestion rates
- **Use Case**: Main dashboard for monitoring overall system health

### 1.2. Home Assistant Monitoring (`02-home-assistant.json`)

- **Purpose**: Monitor Home Assistant integration and metrics
- **Key Metrics**:
  - Home Assistant entity states
  - Integration status
  - Data flow from Home Assistant to InfluxDB
  - Automation execution metrics
- **Use Case**: Track Home Assistant performance and integration health

### 1.3. System Monitoring (`03-system.json`)

- **Purpose**: Monitor system-level metrics and performance
- **Key Metrics**:
  - CPU usage and load averages
  - Memory usage and availability
  - Disk space and I/O
  - Network traffic
- **Use Case**: System administration and performance tuning

### 1.4. InfluxDB Monitoring (`04-influxdb.json`)

- **Purpose**: Monitor InfluxDB database performance and health
- **Key Metrics**:
  - Database size and growth
  - Query performance
  - Data retention and compaction
  - Connection statistics
- **Use Case**: Database administration and optimization

### 1.5. Grafana Monitoring (`05-grafana.json`)

- **Purpose**: Monitor Grafana server performance and usage
- **Key Metrics**:
  - Dashboard usage statistics
  - Alert rule performance
  - User activity
  - Plugin status
- **Use Case**: Grafana administration and user management

## 2. Installation

### 2.1. Automatic Installation

Dashboards are automatically installed when you start the InfluxDB Stack add-on:

1. Start the add-on
2. Wait for all services to initialize
3. Access Grafana through the add-on interface
4. Dashboards will appear automatically in an "InfluxDB Stack" folder

### 2.2. Manual Installation

To manually install or update dashboards:

1. Access Grafana UI
2. Go to **Dashboards** → **Import**
3. Upload the JSON files from this directory
4. Configure the InfluxDB data source if needed

## 3. Usage

### 3.1. Viewing Dashboards

1. Open Grafana through the InfluxDB Stack interface
2. Navigate to **Dashboards**
3. All dashboards will be available in the "InfluxDB Stack" folder
4. Click on any dashboard to view it

### 3.2. Customizing Dashboards

You can customize dashboards to fit your needs:

1. Open the dashboard you want to modify
2. Click the **Edit** button (pencil icon)
3. Modify panels, queries, or layout as needed
4. Save your changes

## 4. Data Source Configuration

All dashboards expect an InfluxDB data source with UID `influxdb`. If your data source has a different UID:

1. Edit the dashboard JSON file
2. Find and replace all instances of `"uid": "influxdb"`
3. Replace `"uid": "influxdb"` with your actual data source UID
4. Re-import the dashboard

## 5. Troubleshooting

### 5.1. Common Issues

**No data showing in dashboards:**
1. Verify InfluxDB data source is configured correctly
2. Check that metrics are being collected (visit InfluxDB UI)
3. Ensure time range is appropriate
4. Verify metric names match your actual InfluxDB metrics

**Dashboard import errors:**
1. Check JSON syntax is valid
2. Verify Grafana version compatibility
3. Ensure all required plugins are installed

### 5.2. Metric Requirements

Dashboards expect the following metric sources:

- **InfluxDB**: `influxdb_*` metrics
- **Grafana**: `grafana_*` metrics
- **System**: `node_*` metrics (if node_exporter is enabled)
- **Home Assistant**: `homeassistant_*` metrics (when integration is enabled)

## 6. Customization

To create custom dashboards:

1. Use the existing dashboards as templates
2. Modify queries to use your specific metrics
3. Adjust visualization types and layouts
4. Test thoroughly before deploying

Query examples:
- InfluxDB metrics: `from(bucket: "telegraf") |> range(start: -1h)`
- System metrics: `from(bucket: "system") |> range(start: -5m)`

## 7. Support

For dashboard issues:
- Check the troubleshooting section above
- Review InfluxDB logs for data collection issues
- Open an issue on GitHub with dashboard details

## 8. License

These dashboards are part of the InfluxDB Stack add-on project and are licensed under the MIT License.
