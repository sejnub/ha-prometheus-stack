# Changelog

All notable changes to this add-on will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 2.4.0 - 2025-01-27

### 🎉 Major Milestone: VS Code Ingress Integration Complete

### Added

- **Version Display**: Version automatically displayed in web interface header
- **Build-Time Version Injection**: Single source of truth for version from config.json
- **VS Code Start/Stop Controls**: Fully functional VS Code management in both test-mode and addon-mode

### Fixed

- **🔧 VS Code Ingress URLs**: Complete fix for VS Code start/stop buttons not working in addon-mode
- **Cross-Mode Compatibility**: Seamless operation in both Home Assistant ingress and direct access modes
- **URL Construction**: Intelligent detection and proper routing for API calls within ingress context

### Improved

- **Code Quality**: Clean, production-ready code without debugging artifacts
- **User Experience**: Reliable VS Code controls with proper status indication
- **DRY Principle**: Eliminated version redundancy across codebase

### Technical Notes

- **Home Assistant Caching**: Discovered addon uninstall/reinstall required to clear HA's aggressive file caching
- **Ingress Context Detection**: Smart URL construction based on pathname analysis
- **Cross-Browser Compatibility**: Verified working across different browsers

## 2.3.9 - 2025-01-27

### Added

- **Version Display**: Added version display in web interface header
- **Build-Time Version Injection**: Version is automatically extracted from config.json and injected into HTML during Docker build
- **VS Code Ingress Fix**: Fixed VS Code start/stop buttons not working in addon-mode with proper URL construction

### Improved

- **DRY Principle**: Eliminated version redundancy by using single source of truth (config.json)
- **Cross-Mode Compatibility**: VS Code buttons now work correctly in both test-mode and addon-mode

## 2.3.8 - 2025-01-27

### Fixed

- **VS Code API URL Construction**: Fixed absolute URL construction for Home Assistant ingress context
- **Ingress Path Resolution**: Uses `window.location.pathname` to build proper ingress URLs  
- **API Call Routing**: Ensures API calls stay within addon's ingress context (`/addon_slug/ingress/api/vscode/status`)
- **Frontend Fix**: Addresses issue where relative URLs weren't resolving correctly in ingress mode

### Technical Details

- Changed getApiUrl() to build absolute URLs using current window location
- Constructs URLs like: `origin + pathname + '/' + endpoint`
- Should resolve to proper ingress URLs instead of breaking out to HA root
- Maintains compatibility with test-mode using relative paths

## 2.3.6 - 2025-01-27

### Fixed

- **VS Code API URLs in Addon-Mode**: Improved URL resolution for Home Assistant ingress context
- **Ingress Detection**: Added smart detection of ingress vs test mode for proper API URLs
- **URL Construction**: Uses `new URL()` constructor for proper relative URL resolution
- **Cross-Mode Compatibility**: Enhanced support for both addon-mode and test-mode API calls

### Technical Details

- Added `getApiUrl()` function that detects ingress context by checking pathname
- In ingress mode: uses `new URL(endpoint, currentUrl)` for proper resolution
- In test mode: uses simple relative paths as before
- Should resolve API calls to correct ingress URLs instead of Home Assistant root

## 2.3.5 - 2025-01-27

### Fixed

- **Circular Dependency**: Removed circular dependency between vscode-api and user services
- **Test-Mode Compatibility**: Fixed s6-rc-compile error that prevented test-mode startup
- **Service Architecture**: vscode-api no longer depends on user service to avoid dependency loop
- **Startup Reliability**: Timeout mechanism handles initialization without requiring dependency

### Technical Details

- Removed `/etc/s6-overlay/s6-rc.d/vscode-api/dependencies.d/user` dependency file
- user bundle includes vscode-api, so vscode-api cannot depend on user (circular)
- Timeout mechanism in vscode-api/run script handles `/tmp/.init-complete` gracefully
- Both test-mode and addon-mode now start services correctly

## 2.3.4 - 2025-01-27

### Improved

- **VS Code Service Reliability**: Added timeout mechanism to vscode-api service startup
- **Cross-Mode Compatibility**: Better handling of test-mode vs addon-mode differences  
- **Error Prevention**: Prevents infinite waiting if user service fails to start
- **Startup Robustness**: 5-second timeout with fallback for edge cases

### Technical Details

- Added timeout loop (10 attempts × 0.5s = 5 seconds max) for `/tmp/.init-complete`
- Different behavior for addon-mode (longer wait) vs test-mode (shorter wait)
- Enhanced logging for better debugging of startup issues
- Prevents the service from hanging indefinitely in edge cases

## 2.3.3 - 2025-01-27

### Fixed

- **Service Dependencies**: Added missing user service dependency for vscode-api service
- **Startup Sequence**: Ensures `/tmp/.init-complete` is created before vscode-api starts waiting for it
- **Fresh Installations**: Prevents vscode-api from hanging indefinitely on first startup
- **Service Reliability**: Improves overall service startup reliability and order

### Technical Details

- Created `/etc/s6-overlay/s6-rc.d/vscode-api/dependencies.d/user` dependency file
- Ensures user service (which creates `/tmp/.init-complete`) runs before vscode-api service
- Prevents the initialization deadlock that required manual intervention
- All fresh installations should now start VS Code API service correctly

## 2.3.2 - 2025-01-27

### Fixed

- **VS Code API URL Resolution**: Improved fix for VS Code control buttons in addon-mode
- **Ingress Context**: Changed from `./api/vscode/*` to `api/vscode/*` for better ingress compatibility  
- **Service Dependencies**: Fixed user service not starting automatically, which caused vscode-api to wait indefinitely
- **Cross-Mode Compatibility**: Ensures VS Code buttons work correctly in both test-mode and addon-mode

### Technical Details

- Root cause was user service not running → `/tmp/.init-complete` never created → vscode-api stuck waiting
- Fixed service dependency chain to ensure proper startup sequence
- Improved API URL construction for Home Assistant ingress context
- Backend VS Code API server functionality confirmed working correctly

## 2.3.1 - 2025-01-27

### Fixed

- **VS Code Start/Stop Buttons**: Fixed VS Code control buttons not working in addon-mode
- **API URL Resolution**: Changed from absolute paths (`/api/vscode/*`) to relative paths (`./api/vscode/*`)
- **Home Assistant Ingress**: VS Code API calls now stay within ingress context instead of breaking out to Home Assistant root
- **Cross-Mode Compatibility**: VS Code buttons now work correctly in both test-mode and addon-mode

### Technical Details

- The issue was that absolute API paths (`/api/vscode/status`) resolved to Home Assistant's root (`http://homeassistant.internal:8123/api/vscode/status`) in addon-mode
- Fixed by using relative paths (`./api/vscode/status`) which stay within the addon's ingress context
- Backend VS Code API server was working correctly - the issue was purely frontend URL resolution
- All API endpoints (`/api/vscode/status`, `/api/vscode/start`, `/api/vscode/stop`) now work in both modes

## 2.3.0 - 2025-01-27

### Added

- **VS Code Web Control Interface**: Start and stop VS Code directly from the addon's main web page
- **Real-time VS Code Status**: Live status indicator showing VS Code running/stopped state
- **VS Code API Server**: REST API endpoints for service control (`/api/vscode/status`, `/api/vscode/start`, `/api/vscode/stop`)
- **CPU Usage Optimization**: Stop VS Code when not needed to reduce CPU usage by ~50%
- **Auto-refresh Status**: VS Code status automatically updates every 30 seconds
- **Interactive Control Buttons**: Start/Stop buttons with visual feedback and loading states
- **Command Line Tools**: Added `vscode-toggle` script for manual VS Code control via SSH

### Changed

- Enhanced main dashboard with VS Code control panel including status and buttons
- Added new s6-overlay service `vscode-api` for web-based VS Code management
- Updated NGINX configuration to route VS Code API requests
- Improved user experience with on-demand VS Code access

### Technical Details

- New Python-based API server on port 8081 for VS Code service management
- Uses s6-overlay service control commands (`s6-rc`) for reliable service management
- All new functionality is additive - existing features unchanged
- Proper error handling and graceful fallbacks for all control operations

## 2.2.9 - 2025-01-27

### Fixed

- Fixed GitHub Actions workflow to remove armv7 from multi-architecture build platforms.
- Removed `linux/arm/v7` from `.github/workflows/build.yml` platforms list.
- This resolves the build failure where GitHub Actions was still trying to build for armv7.
- Multi-architecture builds now only target supported platforms (linux/amd64, linux/arm64).

## 2.2.8 - 2025-01-27

### Fixed

- Added explicit error handling for unsupported architectures in Dockerfile.
- Build now fails fast with clear error message for unsupported platforms.
- Resolved multi-architecture build issues - GitHub Actions now builds successfully.
- Confirmed working build for supported architectures (amd64, aarch64).

## 2.2.7 - 2025-01-27

### Fixed

- Fixed multi-architecture build by removing armv7 references from Dockerfile.
- Removed armv7l case from architecture detection and ARM_ARCH variable.
- Simplified karma download to use ARCH only, aligning with supported architectures.
- Ensures build only targets supported platforms (amd64, aarch64).

## 2.2.6 - 2025-01-27

### Fixed

- Fixed VS Code startup restart loop in test mode by improving copy logic in code-server run script.
- VS Code now only copies settings file when needed, preventing infinite restart when workspace equals source location.
- Added `/opt/code-server/data/logs` directory creation for cleaner startup.
- VS Code now works properly in both test and addon modes without restart issues.

## 2.2.5 - 2025-01-27

### Fixed

- Added missing `.vscode/settings.json` file to git repository (was excluded by .gitignore).
- Fixed Docker build failure: `/rootfs/etc/.vscode`: not found error.
- VS Code explorer excludes now work properly in both test and addon modes.

## 2.2.4 - 2025-01-27

### Fixed

- Fixed Docker build failure by ensuring VS Code settings directory is properly created and copied.
- Enhanced .vscode directory creation with proper permissions during build process.
- Maintained runtime copying logic in code-server to ensure settings work in addon mode.

## 2.2.3 - 2025-01-27

### Fixed

- Always copy `.vscode/settings.json` into the workspace at startup so VS Code explorer excludes work in addon mode.

## 2.2.2 - 2025-01-27

### Changed

- Removed armv7 from supported architectures (no code-server support for armv7).

## 2.2.1 - 2025-01-27

### Changed

- Patch release: documentation, scripts, and minor improvements from previous commit.

## 2.2.0 - 2025-01-27

### Added

- Sectioned and improved markdownlint compliance for all documentation and template files.
- Added `.vscode/settings.json` to control VS Code explorer folder visibility for a focused config editing experience.

### Changed

- Updated VS Code explorer to only show relevant configuration folders by default.
- Improved and standardized markdown formatting in `CHANGELOG.md`, `VSCODE_GUIDE.md`, `RELEASE_TEMPLATE.md`, `ADDON_CHECKLIST.md`, and `temp.md`.
- Updated `config.json` version to 2.2.0.

### Fixed

- Removed invalid `files.exclude` block from `config.json` (now only in `.vscode/settings.json`).
- Fixed markdownlint issues and formatting errors across all documentation files.
- Ensured changelog and documentation are markdownlint-compliant and easy to maintain.

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