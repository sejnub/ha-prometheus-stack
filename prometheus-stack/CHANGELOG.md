# Changelog

All notable changes to this add-on will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 2.2.0 - 2025-01-27

### Added

- (Describe new features here)

### Changed

- (Describe changes here)

### Fixed

- (Describe fixes here)

- [2.1.0 - 2025-01-27](#210---2025-01-27)
  - [Added](#added)
  - [Changed](#changed)
  - [Technical Improvements](#technical-improvements)
- [2.0.0 - 2025-01-27](#200---2025-01-27)
  - [Added](#added-1)
  - [Changed](#changed-1)
  - [Fixed](#fixed)
  - [Technical Improvements](#technical-improvements-1)
- [1.11.29 - 2025-01-27](#11129---2025-01-27)
  - [Fixed](#fixed-1)
  - [Changed](#changed-2)
- [1.11.24 - 2025-01-27](#11124---2025-01-27)
  - [Fixed](#fixed-2)
- [1.11.23 - 2025-01-27](#11123---2025-01-27)
  - [Fixed](#fixed-3)
- [1.11.22 - 2025-01-27](#11122---2025-01-27)
  - [Changed](#changed-3)
- [1.11.21 - 2025-01-27](#11121---2025-01-27)
  - [Fixed](#fixed-4)
- [1.11.20 - 2025-01-27](#11120---2025-01-27)
  - [Fixed](#fixed-5)
- [1.11.19 - 2025-01-27](#11119---2025-01-27)
  - [Fixed](#fixed-6)
- [1.11.18 - 2025-01-27](#11118---2025-01-27)
  - [Fixed](#fixed-7)
- [1.11.17 - 2025-01-27](#11117---2025-01-27)
  - [Fixed](#fixed-8)
- [1.11.16 - 2025-01-27](#11116---2025-01-27)
  - [Fixed](#fixed-9)
- [1.11.15 - 2025-01-27](#11115---2025-01-27)
  - [Fixed](#fixed-10)
- [1.11.14 - 2025-01-27](#11114---2025-01-27)
  - [Fixed](#fixed-11)
- [1.11.13 - 2025-01-27](#11113---2025-01-27)
  - [Fixed](#fixed-12)
  - [Added](#added-2)
  - [Changed](#changed-4)
- [1.11.12 - 2025-01-27](#11112---2025-01-27)
  - [Changed](#changed-5)
- [1.11.11 - Previous Release](#11111---previous-release)
  - [Features](#features)
  - [Components](#components)
  - [Configuration Options](#configuration-options)
  - [Access](#access)
  - [Technical Details](#technical-details)

## 2.1.0 - 2025-01-27

### Added

- **VS Code Integration**: Full-featured code editor with extensions support
- **Code-Server**: VS Code Server (v4.19.1) for browser-based development
- **VS Code Configuration**: Enable/disable, password protection, and workspace configuration
- **VS Code Ingress Support**: Access VS Code through Home Assistant ingress at `/vscode/`
- **Direct VS Code Access**: Direct port access at 8443 for full functionality
- **VS Code Health Monitoring**: Integrated health checks for VS Code service

### Changed

- **BREAKING**: Added new port 8443 for VS Code (disabled by default, use ingress)
- **BREAKING**: Updated add-on description to include VS Code
- Enhanced Dockerfile with Node.js, npm, git, and Python3 for VS Code extensions
- Updated NGINX configuration to include VS Code routing
- Enhanced main dashboard with VS Code access links
- Updated test configuration to include VS Code options

### Technical Improvements

- VS Code service integrated into S6-Overlay service management
- Cross-mode compatible VS Code configuration (test, github, addon modes)
- Persistent VS Code data and extensions storage
- Proper service dependency management for VS Code
- Comprehensive VS Code documentation and access instructions

## 2.0.0 - 2025-01-27

### Added

- **Major Release**: Prometheus Stack 2.0.0 with comprehensive improvements
- **Cross-Mode Compatibility**: All services now work reliably in test, github, and addon modes
- **Standardized Service Management**: Complete S6-Overlay service script standardization
- **Enhanced Documentation**: Comprehensive README standardization across all components

### Changed

- **BREAKING**: Improved service dependency management for more reliable startup
- **BREAKING**: Standardized timeout handling across all services (30 attempts, 0.5s sleep, 15s total)
- **BREAKING**: Replaced bashio::log functions with echo for cross-mode compatibility
- Enhanced error handling and logging consistency across all services
- Improved service startup order and dependency declarations

### Fixed

- **Service Scripts**: Standardized shebang lines across all S6-Overlay services
- **Dependencies**: Added missing legacy-cont-init dependencies to blackbox-exporter and nginx
- **Variables**: Fixed undefined variables in karma run script
- **Logging**: Ensured consistent error handling and logging format
- **Documentation**: Fixed all markdownlint errors and standardized formatting

### Technical Improvements

- All S6-Overlay service scripts now use consistent structure
- Cross-mode compatible logging (test, github, addon modes)
- Proper service dependency declarations for reliable startup
- Enhanced error messages with consistent formatting and timeout information
- Comprehensive documentation with Table of Contents and standardized sections

## 1.11.29 - 2025-01-27

### Fixed

- **S6-Overlay Service Scripts**: Standardized all service scripts for cross-mode compatibility
- Fixed inconsistent shebang lines across all service scripts
- Standardized timeout handling (30 attempts, 0.5s sleep, 15s total) for all services
- Replaced `bashio::log...` functions with `echo` for compatibility across test, github, and addon modes
- Added missing dependencies (legacy-cont-init) to blackbox-exporter and nginx services
- Fixed undefined variables in karma run script
- Ensured consistent error handling and logging format across all services

### Changed

- All S6-Overlay service scripts now use consistent structure and cross-mode compatible logging
- Improved service dependency declarations for proper startup order
- Enhanced error messages with consistent formatting and timeout information

## 1.11.24 - 2025-01-27

### Fixed

- Fixed `test-config.sh` health check endpoint to remove `/prometheus/` prefix.
- Resolves timeout issues in GitHub Actions configuration testing phase.
- Aligns test scripts with the simplified Prometheus configuration from v1.11.23.

## 1.11.23 - 2025-01-27

### Fixed

- **MAJOR FIX**: Simplified nginx ingress configuration to resolve URL breakout issues in Home Assistant.
- Reverted complex path-aware Prometheus configuration back to simple proxy approach.
- Fixed health check endpoints to work with standard Prometheus setup (removed `/prometheus/` prefixes).
- All ingress paths now work correctly: `/prometheus/`, `/alertmanager/`, `/karma/`, `/blackbox/`.
- Resolved client-side navigation issues that were causing timeouts in Home Assistant ingress context.

## 1.11.22 - 2025-01-27

### Changed

- Attempted direct proxy to `/graph` endpoint to avoid client-side redirects.
- Added separate API and static file routing.

## 1.11.21 - 2025-01-27

### Fixed

- Corrected the `test-config.sh` script to use the proper `/prometheus/-/ready` health endpoint.
- This resolves the timeout failure seen in GitHub Actions during the configuration testing phase.
- Aligns all test scripts to be compatible with the path-aware Prometheus configuration.

## 1.11.20 - 2025-01-27

### Fixed

- Fixed Prometheus self-scrape functionality in test mode by updating `metrics_path`.
- Aligned `prometheus.yml` with the new `/prometheus/metrics` endpoint.
- Corrected the health check script to use the proper `/prometheus/-/ready` endpoint.

## 1.11.19 - 2025-01-27

### Fixed

- Reverted environment-based Prometheus configuration that was breaking test mode
- Added comprehensive sub_filter rules to rewrite URLs in Prometheus web interface content
- Fixed nginx content filtering to maintain /prometheus/ prefix in all HTML/JS URLs
- Should resolve ingress context breakout by rewriting client-side URLs at proxy level
- Maintains compatibility with both test mode and Home Assistant addon mode

## 1.11.18 - 2025-01-27

### Fixed

- Added environment-based Prometheus configuration for proper ingress handling
- Prometheus now configures external-url and route-prefix only in Home Assistant addon mode
- Uses SUPERVISOR_TOKEN detection to differentiate between test and addon modes
- Should resolve client-side URL issues causing ingress context breakout

## 1.11.17 - 2025-01-27

### Fixed

- Completely eliminated redirects for Prometheus main UI to prevent ingress context breakout
- Changed from redirect to direct proxy to Prometheus graph endpoint
- Fixed persistent timeout and URL breakout issue in Home Assistant addon mode
- Removed 301 redirect that was causing browser URL changes outside ingress context

## 1.11.16 - 2025-01-27

### Fixed

- Fixed health check script to accept 301 redirects as valid responses
- Updated test suite to handle new nginx redirect configuration for Prometheus
- Resolved GitHub Actions and test mode failures due to unexpected 301 status code

## 1.11.15 - 2025-01-27

### Fixed

- Fixed Prometheus main UI completely breaking out of Home Assistant ingress context
- Added nginx-level redirect from `/prometheus/` to `/prometheus/graph` to prevent external redirects
- Reverted Prometheus configuration to prevent it from issuing redirects that break ingress
- Fixed timeout issue when accessing Prometheus main dashboard through Home Assistant

## 1.11.14 - 2025-01-27

### Fixed

- Fixed Prometheus main UI timeout issue in Home Assistant ingress mode
- Improved nginx redirect handling for Prometheus `/graph` endpoint
- Fixed redirect rewriting to properly maintain `/prometheus/` prefix in ingress context

## 1.11.13 - 2025-01-27

### Fixed

- Fixed ingress routing issue where all service links returned 404 errors in Home Assistant addon mode
- Changed absolute paths to relative paths in index.html for proper ingress compatibility

### Added

- Added `full-test.sh` script for complete automated test cycle (cleanup → build → health check)
- Enhanced test documentation with new full-test workflow

### Changed

- Improved testing workflow with comprehensive error handling and colored output
- Updated test README with better structure and new script documentation

## 1.11.12 - 2025-01-27

### Changed

- Version bump for testing and deployment

## 1.11.11 - Previous Release

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