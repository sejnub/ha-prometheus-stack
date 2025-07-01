# Grafana Dashboards for Prometheus Stack

This directory contains pre-configured Grafana dashboards for monitoring your Prometheus Stack add-on.

## Table of Contents

- [Table of Contents](#table-of-contents)
- [1. Available Dashboards](#1-available-dashboards)
  - [1.1. Prometheus Stack Overview (`01-overview.json`)](#11-prometheus-stack-overview-01-overviewjson)
  - [1.2. Home Assistant Monitoring (`02-home-assistant.json`)](#12-home-assistant-monitoring-02-home-assistantjson)
  - [1.3. Blackbox Exporter Monitoring (`03-blackbox-exporter.json`)](#13-blackbox-exporter-monitoring-03-blackbox-exporterjson)
  - [1.4. Alertmanager Monitoring (`04-alertmanager.json`)](#14-alertmanager-monitoring-04-alertmanagerjson)
  - [1.5. Prometheus Server Monitoring (`05-prometheus.json`)](#15-prometheus-server-monitoring-05-prometheusjson)
- [2. Installation](#2-installation)
  - [2.1. Option 1: Manual Import](#21-option-1-manual-import)
  - [2.2. Option 2: Automatic Provisioning (Recommended)](#22-option-2-automatic-provisioning-recommended)
  - [2.3. Option 3: Home Assistant Add-on](#23-option-3-home-assistant-add-on)
- [3. Configuration](#3-configuration)
  - [3.1. Data Source](#31-data-source)
  - [3.2. Customization](#32-customization)
- [4. Troubleshooting](#4-troubleshooting)
  - [4.1. No Data Showing](#41-no-data-showing)
  - [4.2. Missing Metrics](#42-missing-metrics)
  - [4.3. Performance Issues](#43-performance-issues)
- [5. Metric Sources](#5-metric-sources)
- [6. Support](#6-support)
- [7. License](#7-license)

## Home Dashboard

The file `home.json` contains the default dashboard that should be set as the home dashboard in Grafana. While the file is named `home.json` to indicate its role as the home dashboard, it is titled "Addon Components Monitoring" to describe its content. This dashboard provides an immediate overview of all add-on component statuses when users first log in to Grafana.

To set this as your home dashboard in Grafana:
1. Log in to Grafana
2. Go to the "Addon Components Monitoring" dashboard
3. Click the star icon to favorite it
4. Go to Grafana Settings → Preferences
5. Under "Home Dashboard", select "Addon Components Monitoring"

## 1. Available Dashboards

### 1.1. Prometheus Stack Overview (`01-overview.json`)

- **Purpose**: High-level overview of all monitored services
- **Features**:
  - Services status summary
  - Response times across all probes
  - Overall uptime percentage
  - Services grouped by monitoring category
  - Complete status table

### 1.2. Home Assistant Monitoring (`02-home-assistant.json`)

- **Purpose**: Detailed monitoring of Home Assistant instance
- **Features**:
  - Home Assistant service status
  - CPU and memory usage
  - Entity states count
  - Entity states by domain
  - Detailed entity states table

### 1.3. Blackbox Exporter Monitoring (`03-blackbox-exporter.json`)

- **Purpose**: Monitor all HTTP/TCP probes and their performance
- **Features**:
  - Probe success rates
  - Response times for all probes
  - HTTP status codes
  - SSL certificate expiry monitoring
  - Complete probe status table

### 1.4. Alertmanager Monitoring (`04-alertmanager.json`)

- **Purpose**: Monitor alert management and notification system
- **Features**:
  - Currently firing alerts count
  - Invalid alerts tracking
  - Notifications sent/failed
  - Alert trends over time
  - Notification rate monitoring

### 1.5. Prometheus Server Monitoring (`05-prometheus.json`)

- **Purpose**: Monitor Prometheus server performance and health
- **Features**:
  - Scrape errors and limits
  - Sample processing metrics
  - Active series count
  - Storage performance
  - Data ingestion rates

## 2. Installation

### 2.1. Option 1: Manual Import

1. Open Grafana in your browser
2. Go to **Dashboards** → **Import**
3. Upload each JSON file individually
4. Select your Prometheus data source
5. Import the dashboard

### 2.2. Option 2: Automatic Provisioning (Recommended)

1. Copy the `dashboard-provider.yml` to your Grafana provisioning directory
2. Copy all JSON files to the same directory
3. Restart Grafana
4. Dashboards will appear automatically in a "Prometheus Stack" folder

### 2.3. Option 3: Home Assistant Add-on

If using this as a Home Assistant add-on:

1. The dashboards will be automatically provisioned
2. Access Grafana through the add-on interface
3. All dashboards will be available in the "Prometheus Stack" folder

## 3. Configuration

### 3.1. Data Source

All dashboards expect a Prometheus data source with UID `prometheus`. If your data source has a different UID:

1. Edit each dashboard JSON file
2. Replace `"uid": "prometheus"` with your actual data source UID
3. Save and re-import

### 3.2. Customization

- **Time Range**: Default is last 1 hour, adjustable via dashboard controls
- **Refresh Rate**: Default is 30 seconds, can be changed per dashboard
- **Thresholds**: Color-coded thresholds are set for critical values
- **Units**: Appropriate units are set for each metric type

## 4. Troubleshooting

### 4.1. No Data Showing

1. Verify Prometheus data source is configured correctly
2. Check that metrics are being collected (visit Prometheus targets page)
3. Ensure time range includes data collection period
4. Verify metric names match your actual Prometheus metrics

### 4.2. Missing Metrics

Some metrics may not be available depending on your configuration:

- Home Assistant metrics require Prometheus integration to be enabled
- SSL metrics require HTTPS endpoints
- Alertmanager metrics require alerts to be configured

### 4.3. Performance Issues

- Reduce refresh rate for better performance
- Limit time range for large datasets
- Consider using recording rules for complex queries

## 5. Metric Sources

The dashboards use metrics from:

- **Prometheus**: `up`, `prometheus_*` metrics
- **Blackbox Exporter**: `probe_*` metrics
- **Alertmanager**: `alertmanager_*` metrics
- **Home Assistant**: `hass_*` metrics (when Prometheus integration is enabled)

## 6. Support

For issues with the dashboards:

1. Check Grafana logs for errors
2. Verify Prometheus targets are healthy
3. Test queries directly in Prometheus UI
4. Ensure all required exporters are running

For general support:

- [Documentation](https://github.com/sejnub/ha-prometheus-stack/wiki)
- [Issue Tracker](https://github.com/sejnub/ha-prometheus-stack/issues)

## 7. License

MIT License - see [LICENSE](../LICENSE) file for details
