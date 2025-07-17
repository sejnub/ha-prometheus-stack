# Migration Summary: Prometheus Stack → InfluxDB Stack

## Overview

This document summarizes the complete migration from a Prometheus-based monitoring stack to an InfluxDB 2.x-based time-series analytics platform.

## Architecture Changes

### Before (Prometheus Stack)
- **Prometheus**: Time-series database and monitoring system
- **Alertmanager**: Alert routing and notification management
- **Karma**: Modern web UI for alert management
- **Blackbox Exporter**: External service monitoring
- **Grafana**: Visualization and dashboards
- **VS Code**: Development environment
- **NGINX**: Ingress routing

### After (InfluxDB Stack)
- **InfluxDB 2.x**: Purpose-built time-series database (replaces Prometheus)
- **Grafana**: Visualization, dashboards, and built-in alerting (replaces Alertmanager + Karma)
- **VS Code**: Development environment (unchanged)
- **NGINX**: Ingress routing (simplified)

## Key Benefits

1. **Simplified Architecture**: Reduced from 7 services to 4 services
2. **Modern Time-Series Database**: InfluxDB 2.x with Flux query language
3. **Integrated Alerting**: Grafana's built-in alerting replaces separate Alertmanager
4. **Better Performance**: InfluxDB 2.x optimized for time-series data
5. **Unified Interface**: InfluxDB UI as primary interface
6. **Reduced Complexity**: Fewer moving parts and configuration files

## File Changes

### Removed Files
- `prometheus.yml` - Prometheus configuration
- `blackbox.yml` - Blackbox Exporter configuration
- `alertmanager.yml` - Alertmanager configuration (generated)
- `karma.yml` - Karma configuration (generated)
- Service directories for removed components

### Modified Files
- `Dockerfile` - Updated to install InfluxDB 2.x instead of Prometheus stack
- `config.json` - New configuration options for InfluxDB
- `grafana.ini` - Added alerting configuration
- `ingress.conf` - Simplified routing to InfluxDB and Grafana
- `index.html` - Updated to feature InfluxDB as primary interface
- `00-init.sh` - InfluxDB setup instead of Alertmanager/Karma generation

### New Files
- `influxdb.yml` - InfluxDB datasource configuration for Grafana
- InfluxDB service configuration files

## Configuration Changes

### Old Configuration Options
```yaml
alertmanager_receiver: "default"
alertmanager_to_email: "your@email.com"
blackbox_targets:
  - name: "Home Assistant"
    url: "http://supervisor/core"
```

### New Configuration Options
```yaml
influxdb_org: "my-org"
influxdb_bucket: "my-bucket"
influxdb_username: "admin"
influxdb_password: "admin123"
influxdb_token: ""
grafana_admin_password: "admin"
```

## Port Changes

### Before
- Prometheus: 9090
- Alertmanager: 9093
- Karma: 8080
- Blackbox Exporter: 9115
- Grafana: 3000
- VS Code: 8443
- NGINX: 80

### After
- InfluxDB: 8086
- Grafana: 3000
- VS Code: 8443
- NGINX: 80

## Service Access

### Before
- **Primary Interface**: Karma (alert management)
- **Monitoring**: Prometheus UI
- **Dashboards**: Grafana
- **Alerting**: Alertmanager

### After
- **Primary Interface**: InfluxDB UI (data exploration and querying)
- **Dashboards**: Grafana
- **Alerting**: Grafana (built-in alerting)

## Migration Steps Completed

1. ✅ **Updated Dockerfile**: Replaced Prometheus components with InfluxDB 2.x
2. ✅ **Removed Services**: Cleaned up Prometheus, Alertmanager, Karma, Blackbox Exporter
3. ✅ **Created InfluxDB Service**: New s6-overlay service configuration
4. ✅ **Updated Grafana**: Added alerting configuration and InfluxDB datasource
5. ✅ **Simplified NGINX**: Updated routing for new architecture
6. ✅ **Updated UI**: New index.html featuring InfluxDB as primary interface
7. ✅ **Updated Configuration**: New add-on options for InfluxDB
8. ✅ **Updated Documentation**: README, repository info, and guides
9. ✅ **Updated Test Scripts**: Build and health check scripts
10. ✅ **Updated Sync Tools**: Configuration management tools

## Testing

The migration includes updated test scripts:
- `test/build.sh` - Build and run InfluxDB Stack locally
- `test/health-check.sh` - Verify all services are healthy
- Updated sync tools for configuration management

## Breaking Changes

⚠️ **Important**: This is a major version upgrade (2.x → 3.x) with breaking changes:

1. **Configuration Format**: Completely new configuration options
2. **Data Storage**: InfluxDB uses different data format than Prometheus
3. **Query Language**: Flux instead of PromQL
4. **Alerting**: Grafana alerting instead of Alertmanager
5. **API Endpoints**: Different API structure

## Migration Path for Users

1. **Backup Data**: Export important dashboards and alert rules
2. **Update Configuration**: Use new InfluxDB configuration options
3. **Recreate Dashboards**: Convert Prometheus queries to Flux
4. **Reconfigure Alerts**: Set up alerts in Grafana instead of Alertmanager
5. **Update Integrations**: Point Home Assistant to InfluxDB instead of Prometheus

## Version Information

- **Previous Version**: 2.7.13 (Prometheus Stack)
- **New Version**: 3.0.0 (InfluxDB Stack)
- **InfluxDB Version**: 2.7.12
- **Grafana Version**: 11.3.1

## Repository Changes

- **Old Repository**: `ha-prometheus-stack`
- **New Repository**: `ha-influxdb-stack`
- **Add-on Slug**: `influxdb-stack`
- **Add-on Name**: "InfluxDB Stack"

This migration represents a significant modernization of the monitoring stack, providing better performance, simpler architecture, and more powerful time-series analytics capabilities. 