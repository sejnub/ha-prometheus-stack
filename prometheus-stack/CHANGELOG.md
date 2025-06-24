# Changelog

All notable changes to this add-on will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.11.15] - 2025-01-27

### Fixed
- Fixed Prometheus main UI completely breaking out of Home Assistant ingress context
- Added nginx-level redirect from `/prometheus/` to `/prometheus/graph` to prevent external redirects
- Reverted Prometheus configuration to prevent it from issuing redirects that break ingress
- Fixed timeout issue when accessing Prometheus main dashboard through Home Assistant

## [1.11.14] - 2025-01-27

### Fixed
- Fixed Prometheus main UI timeout issue in Home Assistant ingress mode
- Improved nginx redirect handling for Prometheus `/graph` endpoint
- Fixed redirect rewriting to properly maintain `/prometheus/` prefix in ingress context

## [1.11.13] - 2025-01-27

### Fixed
- Fixed ingress routing issue where all service links returned 404 errors in Home Assistant addon mode
- Changed absolute paths to relative paths in index.html for proper ingress compatibility

### Added
- Added `full-test.sh` script for complete automated test cycle (cleanup → build → health check)
- Enhanced test documentation with new full-test workflow

### Changed
- Improved testing workflow with comprehensive error handling and colored output
- Updated test README with better structure and new script documentation

## [1.11.12] - 2025-01-27

### Changed
- Version bump for testing and deployment

## [1.11.11] - Previous Release

### Features
- Prometheus time-series database for metrics collection
- Alertmanager for alert routing and notification management
- Karma modern web UI for alert management and visualization
- Blackbox Exporter for external service monitoring
- Multi-architecture support (amd64, arm64, armv7)
- Ingress support for seamless Home Assistant integration
- Pre-configured dashboards for Grafana
- Email notifications for alerts
- Dynamic configuration from add-on settings
- Comprehensive monitoring of Home Assistant and add-ons

### Components
- **Prometheus**: Port 9090 (disabled by default, use ingress)
- **Alertmanager**: Port 9093 (disabled by default, use ingress)  
- **Blackbox Exporter**: Port 9115 (disabled by default, use ingress)
- **Karma**: Port 8080 (disabled by default, use ingress)
- **NGINX**: Port 80 (ingress routing)

### Configuration Options
- `alertmanager_receiver`: Name of the default alert receiver
- `alertmanager_to_email`: Email address for alert notifications  
- `home_assistant_url`: URL of your Home Assistant instance
- `home_assistant_token`: Long-lived access token for Home Assistant
- `blackbox_targets`: List of endpoints to monitor with name and URL

### Access
- All services accessible through Home Assistant ingress
- Main dashboard at add-on's web UI
- Individual service access through subpaths:
  - `/prometheus/` - Prometheus UI
  - `/alertmanager/` - Alertmanager UI  
  - `/karma/` - Karma UI
  - `/blackbox/` - Blackbox Exporter UI

### Technical Details
- Built on s6-overlay for service management
- NGINX reverse proxy for ingress routing
- Automatic service health monitoring
- Persistent data storage in `/data`
- Support for both test mode and Home Assistant addon mode 