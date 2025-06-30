# Changelog

All notable changes to this add-on will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 2.6.4 - 2025-06-30

### 🔧 Fixed: Removed Inconsistent VS Code Direct Link

### Removed

- **VS Code Direct Link**: Removed `🚀 Direct VS Code (Port 8443)` link as it was inconsistent with the logical pattern

### Technical Details

**Consistent Logic Applied:**
- **Direct links provided**: Only for services with **ingress limitations** that need port access as backup
- **No direct links**: For services that work fine through Home Assistant's ingress system

**Current Status:**
- **✅ Prometheus**: Direct link (Port 9090) - Has ingress limitations (fails in Addon-mode)
- **✅ Grafana**: Direct link (Port 3000) - Has ingress limitations (doesn't work through ingress)
- **❌ VS Code**: No direct link - Works perfectly through ingress in all modes
- **❌ Alertmanager**: No direct link - Works perfectly through ingress  
- **❌ Blackbox**: No direct link - Works perfectly through ingress
- **❌ Karma**: No direct link - Works perfectly through ingress
- **❌ NGINX**: No direct link - Works perfectly through ingress

**Clarification:**
VS Code's previous start/stop button issues were **frontend API problems**, not ingress problems. The VS Code web interface itself works fine through Home Assistant's ingress system and doesn't require direct port access.

**JavaScript Changes:**
- Removed `setupDirectLink('vscode-direct-link', 8443, 'VS Code');` call
- Simplified direct link management to only handle Prometheus and Grafana

This creates a clear, logical pattern where direct links are only provided for services that actually need them.

## 2.6.3 - 2025-06-30

### 🎨 Simplified: Removed Colored Service Card Borders

### Removed

- **Colored Left Borders**: Removed all colored left border styling from service cards for cleaner, more uniform appearance
- **CSS Classes**: Removed `.limited`, `.controllable`, and `.limited.controllable` styling classes
- **Visual Complexity**: Simplified service card design to focus on content rather than visual indicators

### Technical Details

**CSS Changes:**
- Removed colored border-left styling rules
- Standardized all service cards to use the same white background and subtle shadow
- Removed class-based visual differentiation system

**HTML Changes:**
- Removed all CSS class attributes from service card divs
- All service cards now use the standard `.service-card` class only

**Result:**
All service cards now have a clean, uniform appearance without colored borders. Service characteristics (ingress limitations, controllable features) are still clearly described in the text content but no longer indicated through visual styling.

## 2.6.2 - 2025-06-30

### 🔧 Fixed: Link Consistency & Restored Missing Service

### Fixed

- **Restored Karma Service**: Added back the missing Karma alert dashboard service card that was accidentally removed
- **Link Icon Consistency**: Fixed NGINX status link to use consistent 🔗 icon instead of 📈
- **Direct Link Messages**: Standardized VS Code direct link message format to match Prometheus/Grafana pattern `(Port XXXX - Checking...)`
- **CSS Classes**: Added proper `controllable` class to VS Code and Grafana service cards for visual consistency
- **Service Organization**: Restored proper section comments for better code organization

### Technical Details

**Link Pattern Standardization:**
- **Ingress Links**: All use 🔗 icon with consistent formatting
- **Direct Links**: All use 🚀 icon with consistent `(Port XXXX - Checking...)` format
- **Health/Status**: All use 🏥 icon for health endpoints
- **Metrics**: All use 📈 icon for metrics endpoints

**Service Classification:**
- `limited`: Services with ingress limitations (Prometheus, Grafana)
- `controllable`: Services with start/stop controls (VS Code, Grafana) 
- `limited controllable`: Services with both characteristics (Grafana)

**Current Link Status:**
- **Services with Ingress + Direct**: Prometheus, Grafana, VS Code
- **Services with Ingress Only**: Alertmanager, Blackbox, Karma, NGINX
- **Consistent Explanatory Text**: Applied where relevant for user clarity

## 2.6.1 - 2025-06-30

### 🎨 UI/UX: Consistent Service Card Layout

### Changed

- **Service Card Organization**: Reorganized services into logical groups (Core Monitoring → Visualization → Development → Infrastructure)
- **Consistent Structure**: Standardized all service cards to follow the same layout pattern (description → notes → limitations → controls → links)
- **Link Organization**: Consistent link ordering across all services (UI → Direct → Health → Metrics → Special)
- **Visual Consistency**: Unified styling with consistent colors, spacing, and typography
- **CSS Classes**: Introduced semantic classes (`controllable`, `limited`) with visual indicators
- **Terminology**: Updated naming to use official convention (Test-mode, Addon-mode)

### Technical Details

**Card Structure Standardization:**
- Description section (all services)
- Notes section (where applicable) 
- Limitations section (where applicable)
- Status controls (controllable services)
- Links section (consistent ordering)

**Visual Improvements:**
- Color-coded service types with left border indicators
- Consistent note and limitation styling with proper backgrounds
- Improved button and link styling
- Better spacing and typography hierarchy

**Logical Grouping:**
1. **Core Monitoring**: Prometheus, Alertmanager, Blackbox Exporter
2. **Visualization**: Grafana, Karma  
3. **Development**: VS Code
4. **Infrastructure**: NGINX Status

This creates a more professional, organized interface while preserving all accurate technical information and functionality.

## 2.6.0 - 2025-06-30

### 🎮 MAJOR FEATURE: Grafana Start/Stop Controls

### Added

- **Grafana Control Interface**: Complete start/stop controls identical to VS Code implementation
- **Grafana API Server**: New dedicated API server on port 8082 for Grafana service management
- **Interactive Dashboard**: Real-time status monitoring and control buttons in web interface
- **Resource Management**: Start/stop Grafana on-demand to save CPU resources
- **Status Monitoring**: Live status indicator with automatic 30-second refresh intervals
- **Error Handling**: Comprehensive error reporting and graceful fallback mechanisms

### Technical Implementation

- **`grafana-api-server`**: New Python API server handling `/api/grafana/status`, `/api/grafana/start`, `/api/grafana/stop`
- **s6-overlay Integration**: New `grafana-api` service with proper dependencies and startup sequence
- **NGINX Proxy**: Added `/api/grafana/` endpoint routing to port 8082
- **Frontend Controls**: Status indicator, start/stop buttons, and real-time feedback
- **Service Management**: Uses `s6-rc` and `s6-svc` for reliable service control
- **Multi-method Status**: Combines `s6-svstat` and `ps` checks for robust status detection

### UI/UX Enhancements

- **Consistent Interface**: Matches VS Code control design and behavior
- **Visual Feedback**: Color-coded status (running/stopped/loading/error)
- **User Guidance**: Helpful tips and error messages
- **Responsive Design**: Disabled states and loading indicators
- **Auto-refresh**: Status updates every 30 seconds automatically

### Benefits

- **Resource Optimization**: Stop Grafana when not needed to save CPU/memory
- **Operational Control**: Start services on-demand for maintenance or troubleshooting  
- **Monitoring**: Real-time visibility into service states
- **Consistency**: Unified control interface matching VS Code implementation

This brings Grafana service management to parity with VS Code, providing users complete control over resource-intensive services.

## 2.5.15 - 2025-06-30

### 🏷️ Standardization: Official Naming Convention

### Fixed

- **Naming Convention Alignment**: Standardized all test scripts to use official mode naming convention
- **Consistent Terminology**: Replaced inconsistent mode references throughout test infrastructure

### Changed

- **Test Scripts Naming**: Updated all references to use official three-mode convention:
  - **Test-mode**: Local development environment (Cursor AI)
  - **Github-mode**: CI/CD environment (GitHub Actions)  
  - **Addon-mode**: Real Home Assistant add-on environment
- **Script Messages**: Updated user-facing messages to match official convention
- **Documentation Alignment**: Ensured all test scripts follow README.md naming standards

### Technical Details

**Before**: Mixed terminology ("addon mode", "GitHub Actions mode", "local test mode")
**After**: Consistent official naming (Test-mode, Github-mode, Addon-mode)

**Files Updated**:
- `test/build-test.sh`: Header and startup messages
- `test/health-check.sh`: Environment detection and debug messages

This eliminates confusion and ensures consistent terminology across all project documentation and code.

## 2.5.14 - 2025-06-30

### 🔗 UI/UX: Intelligent Direct Access Links

### Fixed

- **Broken VS Code Direct Link**: Fixed broken link to `http://homeassistant.internal:8443/` when port is disabled
- **Misleading Link Behavior**: All direct links now show actual accessibility status instead of blindly linking
- **User Experience**: No more broken links - disabled ports show helpful alerts with configuration instructions

### Added

- **Smart Link Detection**: All direct access links (Prometheus, Grafana, VS Code) now check port accessibility
- **Dynamic Status Updates**: Links show "Checking..." → "Available" or "Disabled" based on actual port status
- **Helpful Error Messages**: Disabled ports provide clear instructions on which port to enable in addon config
- **Visual Feedback**: Disabled links are styled differently to indicate unavailable features

### Technical Details

**Before**: Static links regardless of port configuration → broken links for disabled ports
**After**: Dynamic port accessibility checking with user-friendly feedback

**Implementation**: 
- Single `setupDirectLink()` function handles all three services (DRY principle)
- Non-blocking `fetch()` checks with graceful fallback
- Consistent UX across Prometheus (9090), Grafana (3000), and VS Code (8443)

## 2.5.12 - 2025-06-30

### ⚡ Performance: Optimized Timeout Handling

### Changed

- **Service Startup Performance**: Replaced fixed timeouts with responsive condition-checking loops
- **Grafana Health Checks**: Reduced retry interval from 2s → 0.5s (4x faster response)
- **VS Code API Service**: Replaced fixed 3-second delay with dynamic s6-overlay readiness checking
- **GitHub Actions CI/CD**: Reduced retry intervals from 2s → 0.5s for faster feedback
- **Container Cleanup**: Improved stop-checking responsiveness from 2s → 0.5s intervals

### Technical Details

**Before**: Fixed delays regardless of actual service readiness
**After**: Dynamic condition checking with 0.5s intervals for optimal responsiveness

**Timeout Period Maintenance:**
- **Grafana**: 30→120 attempts to maintain 60-second total timeout (30×2s → 120×0.5s)
- **Cleanup**: 30→120 attempts to maintain 60-second total timeout (30×2s → 120×0.5s)
- **Response time**: 4x faster when services are ready (2s → 0.5s intervals)

**VS Code Service Improvements:**
- Replaced `sleep 3` with condition check for `s6-svstat` and `s6-rc` availability
- Removed unnecessary `sleep 1` delay in test mode
- Added timeout protection (6 seconds max) with graceful fallback

### Impact

- **Faster Startup**: Services respond immediately when ready instead of waiting for fixed delays
- **Better Resource Utilization**: Reduced unnecessary CPU idle time during startup
- **Improved CI/CD**: 4x faster feedback loops in GitHub Actions
- **More Reliable**: Dynamic condition checking vs blind waiting prevents race conditions

## 2.5.11 - 2025-06-30

### 🔧 CRITICAL FIX: s6-overlay Service Dependencies

### Fixed

- **s6-overlay Service Dependencies**: Corrected ALL service dependency files to be properly empty as per official s6-overlay documentation
- **Service Startup Issues**: Fixed potential service startup problems across the entire stack
- **Documentation Compliance**: Aligned with official s6-overlay documentation requirement for empty dependency files

### Root Cause

All s6-overlay service dependency files incorrectly contained service names when they should be empty files. According to the official s6-overlay documentation, dependency files in `dependencies.d/` should be empty files where the **filename** (not content) indicates the dependency.

### Technical Details

**Affected Files:**
- `/etc/s6-overlay/s6-rc.d/vscode-api/dependencies.d/legacy-cont-init`
- `/etc/s6-overlay/s6-rc.d/prometheus/dependencies.d/blackbox-exporter`
- `/etc/s6-overlay/s6-rc.d/prometheus/dependencies.d/legacy-cont-init`
- `/etc/s6-overlay/s6-rc.d/user/dependencies.d/legacy-cont-init`
- `/etc/s6-overlay/s6-rc.d/karma/dependencies.d/prometheus`
- `/etc/s6-overlay/s6-rc.d/karma/dependencies.d/alertmanager`
- `/etc/s6-overlay/s6-rc.d/grafana/dependencies.d/prometheus`
- `/etc/s6-overlay/s6-rc.d/alertmanager/dependencies.d/legacy-cont-init`

**Before**: Files contained service names (e.g., "prometheus ", "legacy-cont-init")
**After**: All files are empty (0 bytes) with correct filename-based dependency resolution

### Impact

- **Service Reliability**: Ensures proper s6-overlay service dependency resolution
- **Startup Consistency**: Eliminates potential service startup race conditions
- **Documentation Compliance**: Follows official s6-overlay best practices
- **All Environments**: Improves reliability across test mode, addon mode, and CI/CD environments

## 2.5.10 - 2025-06-30

### 🔧 Critical Fix: Grafana Service Startup in Addon Mode

### Fixed

- **Grafana Service Dependencies**: Fixed malformed dependency file that prevented Grafana from starting in addon mode and GitHub Actions
- **s6-overlay Dependency Resolution**: Grafana dependency file now correctly references "prometheus " instead of empty space
- **Environment-Specific Startup**: Grafana now starts consistently across all environments (test mode, addon mode, GitHub Actions)

### Root Cause

The Grafana service dependency file `/etc/s6-overlay/s6-rc.d/grafana/dependencies.d/prometheus` contained only a space character instead of the service name "prometheus ". This malformed dependency prevented s6-overlay from properly resolving the service dependency tree in strict environments (addon mode, GitHub Actions), causing Grafana to never start.

### Technical Details

**Before**: 
- Dependency file: `00000000  20` (space character only)
- Result: s6-overlay cannot resolve Grafana dependencies → service never starts

**After**:
- Dependency file: `70 72 6f 6d 65 74 68 65 75 73 20 0a` ("prometheus " + newline)  
- Result: s6-overlay properly starts Grafana after Prometheus is ready

### Impact

- **Test Mode**: No change (was working due to lenient dependency checking)
- **Addon Mode**: Grafana now starts and is accessible at `http://homeassistant.internal:3000/`
- **GitHub Actions**: Grafana now starts properly in CI environment
- **User Experience**: Complete monitoring stack now works in all deployment modes

## 2.5.9 - 2025-06-30

### 🔧 Enhancement: Complete Testing Suite for All Components

### Added

- **Comprehensive Grafana Testing**: Added Grafana to all test scripts with health checks, configuration validation, and functionality testing
- **Complete VS Code Testing**: Added proper VS Code testing with HTTP status code validation (302 redirect handling)
- **Enhanced build-test.sh**: Now documents all 7 services including Grafana URLs and ingress paths
- **Enhanced health-check.sh**: Now tests all 7 services with individual health checks and functionality tests

### Fixed

- **Missing Component Documentation**: Fixed build-test.sh to include Grafana service URLs, health endpoints, and ingress paths
- **Incomplete Health Checks**: Added Grafana and VS Code to comprehensive health check suite
- **VS Code Test Method**: Fixed VS Code test to properly handle 302 redirects (working behavior)
- **Grafana JSON Parsing**: Fixed Grafana health test to properly parse JSON response format

### Technical Details

**Now Testing All 7 Services:**
1. ✅ Prometheus (metrics collection)
2. ✅ Alertmanager (alert management) 
3. ✅ Blackbox Exporter (endpoint monitoring)
4. ✅ Karma (alert dashboard)
5. ✅ **Grafana** (visualization - newly added)
6. ✅ **VS Code** (development environment - newly added)
7. ✅ NGINX (ingress proxy)

**Comprehensive Test Coverage:**
- **6 Configuration Files**: All service configs validated
- **3 Data Directories**: All persistent storage checked  
- **8 Functionality Tests**: All services + ingress proxy paths
- **7 Basic Health Checks**: Individual service health validation
- **6 Ingress Paths**: All subpath routing tested

### Impact

- **Complete Test Coverage**: Every component in the stack is now properly tested
- **Accurate Documentation**: build-test.sh reflects all available services and endpoints
- **Reliable Health Checks**: Comprehensive validation ensures all services are working correctly
- **Development Confidence**: Full test suite provides confidence in addon functionality

## 2.5.8 - 2025-06-30

### 🔧 Critical Fix: Grafana Network Binding in Addon Mode

### Fixed

- **Grafana Network Accessibility**: Fixed timeout issue when accessing Grafana on port 3000 in addon mode
- **Network Binding**: Added `http_addr = 0.0.0.0` to grafana.ini to bind to all interfaces
- **Container Networking**: Grafana now accessible from outside the addon container via `http://homeassistant.internal:3000/`

### Root Cause

Grafana was defaulting to bind only to localhost (127.0.0.1) inside the addon container, making it inaccessible from the Home Assistant host. Other services (Prometheus, Alertmanager, Blackbox Exporter) already used proper network binding (`:PORT` format = `0.0.0.0:PORT`).

### Technical Details

**Before**: Grafana bound to `127.0.0.1:3000` (localhost only)
**After**: Grafana binds to `0.0.0.0:3000` (all interfaces)

This matches the network configuration pattern used by other services in the stack.

### Impact

- **Test Mode**: No change (already worked)
- **Addon Mode**: Grafana now accessible via direct port access as intended
- **User Experience**: Direct Grafana link now works in both modes

## 2.5.7 - 2025-06-30

### 🔧 Documentation Fix: Corrected Ingress Behavior Descriptions

### Fixed

- **Prometheus Documentation**: Corrected to accurately reflect that Prometheus ingress works in test mode due to relative redirects
- **Grafana Documentation**: Fixed to clearly explain absolute redirect issue (`/login` vs `/grafana/login`) that breaks all ingress access
- **Redirect Behavior Analysis**: Documented the crucial difference between relative redirects (Prometheus) and absolute redirects (Grafana)
- **Mode-Specific Behavior**: Clarified test mode vs addon mode differences for both services

### Technical Clarification

**Prometheus (✅ Test Mode, ❌ Addon Mode):**
- Uses relative redirects that resolve within ingress context in test mode
- Still fails in addon mode due to Home Assistant's complex ingress URL structure

**Grafana (❌ All Modes):**
- Uses absolute redirects (`/login`) that break out of ingress context in any mode
- Requires direct port access (3000) for functionality

### User Interface Updates

- **Prometheus Link**: Changed from "Broken in Ingress" → "Works in Test Mode"
- **Grafana Link**: Changed from "Limited in Ingress" → "Broken - Absolute Redirects"  
- **Recommendation Updates**: Prometheus "Recommended" vs Grafana "Required" for direct access

## 2.5.6 - 2025-06-30

### 🔧 Critical Correction: Addon Mode vs Test Mode Analysis

### Fixed

- **Addon Mode Behavior**: Corrected analysis to properly account for Home Assistant ingress context
- **Both Services Limited**: Both Prometheus and Grafana have ingress limitations in addon mode
- **Root Cause**: Absolute redirects (`/graph`, `/login`) break out of ingress context in addon mode
- **Documentation**: Updated nginx comments to reflect the correct behavior in addon mode

### Key Discovery: Test Mode ≠ Addon Mode

**Test Mode Behavior:**
- Prometheus: `/prometheus/` → redirects to `/graph` → works (shorter path context)
- Grafana: `/grafana/` → redirects to `/login` → limited by `<base href="/">`

**Addon Mode Behavior (Home Assistant Ingress):**
- Prometheus: `/addon_slug/ingress/prometheus/` → redirects to `/graph` → breaks out of ingress context ❌
- Grafana: `/addon_slug/ingress/grafana/` → redirects to `/login` → breaks out of ingress context ❌

### Technical Analysis

Both services fail in addon mode due to **absolute path redirects** that break out of the `/addon_slug/ingress/` context:
- Prometheus redirects to `/graph` instead of relative path
- Grafana redirects to `/login` instead of relative path  
- Both redirects escape the Home Assistant ingress URL structure

### Impact

This explains why both Grafana links appear broken in the user's addon mode testing, despite appearing to work differently in test mode.

## 2.5.5 - 2025-06-30

### 🔧 Major Correction: Prometheus Ingress Actually Works

### Fixed

- **Prometheus Documentation**: Corrected major error - Prometheus does NOT have ingress limitations
- **Root Cause Analysis**: Prometheus uses relative paths (`./static/js/...`) which work perfectly with subpath routing
- **Technical Accuracy**: Updated nginx comments to reflect that Prometheus ingress routing works correctly
- **Grafana vs Prometheus**: Clarified the actual difference - only Grafana has the `<base href="/">` limitation

### Key Discovery

The fundamental difference between Prometheus and Grafana:

**Prometheus (✅ Works with Ingress):**
- Uses relative paths: `src="./static/js/main.js"`
- Path resolution: `/prometheus/` + `./static/js/main.js` = `/prometheus/static/js/main.js` ✅

**Grafana (❌ Limited with Ingress):**  
- Uses `<base href="/">` + relative paths: `href="public/img/icon.png"`
- Path resolution: `/grafana/` + `public/img/icon.png` + `<base href="/">` = `/public/img/icon.png` ❌

### Impact

This correction means users can confidently use Prometheus through both ingress and direct access methods.

## 2.5.4 - 2025-06-30

### 🔧 Fixed: Grafana Direct Access

### Fixed

- **Grafana Port 3000**: Enabled by default to make "Direct Grafana (Recommended)" link actually work
- **User Experience**: Fixed confusing situation where both Grafana links appeared broken
- **Port Configuration**: Updated port description to explain why port 3000 is now enabled
- **Consistent Functionality**: Direct Grafana link now works as intended and recommended

### Background

After documenting the Grafana ingress limitation in v2.5.3, both Grafana links appeared broken to users:
- Ingress link (`/grafana/`) had the documented `<base href="/">` limitation
- Direct link (port 3000) didn't work because the port wasn't exposed

This fix ensures the recommended "Direct Grafana" approach actually works by enabling port 3000 by default.

## 2.5.3 - 2025-06-30

### 🔍 Important Discovery: Grafana Ingress Limitation Documented

### Fixed

- **Grafana Ingress Documentation**: Properly documented that Grafana has the same ingress limitation as Prometheus
- **Subpath Routing Issue**: Confirmed Grafana uses `<base href="/">` which breaks subpath routing in Home Assistant ingress
- **User Interface**: Updated Grafana service card to show limitation warning and recommend direct port access
- **Nginx Configuration**: Added explanatory comments matching Prometheus limitation documentation
- **Consistency**: Both Prometheus and Grafana now properly documented as having the same fundamental limitation

### Root Cause Analysis

Modern web applications like Prometheus and Grafana use `<base href="/">` in their HTML, causing all relative URLs to resolve to the root path instead of the intended subpath (e.g., `/grafana/`). This breaks asset loading and navigation when deployed behind a reverse proxy with subpath routing.

### Technical Details

- **Base Href Issue**: `<base href="/">` in HTML causes `href="public/img/icon.png"` to resolve to `/public/img/icon.png` instead of `/grafana/public/img/icon.png`
- **Asset Loading Failure**: JavaScript, CSS, and images fail to load through ingress, causing "failed to load application files" errors
- **Redirect Problems**: Internal redirects go to root paths (`/login`) instead of subpaths (`/grafana/login`)
- **Same as Prometheus**: Both applications have identical architectural limitations for subpath deployment

### Recommendation

Use direct port access (port 3000 for Grafana, port 9090 for Prometheus) instead of ingress routing for full functionality.

## 2.5.2 - 2025-06-30

### 🔧 Critical Bug Fix

### Fixed

- **Grafana Service Not Starting**: Fixed critical issue where Grafana service was not being started by s6-overlay
- **Missing Service Bundle**: Added missing `/etc/s6-overlay/s6-rc.d/user/contents.d/grafana` file
- **Service Integration**: Grafana now properly included in the user service bundle and starts automatically
- **Web Interface Access**: Grafana dashboard now accessible via `/grafana/` endpoint with proper nginx proxy
- **Health Check**: Grafana health endpoint now returns proper status (`{"database": "ok", "version": "11.3.1"}`)

### Root Cause

The Grafana service directory and configuration existed but was not included in the s6-overlay service bundle, causing the service to never start. This was due to the missing service bundle file that links Grafana to the user service tree.

### Impact

- **Before**: Grafana completely inaccessible, nginx returning 502 errors
- **After**: Full Grafana functionality restored with dashboard access and proper health checks

## 2.5.1 - 2025-01-27

### Fixed

- **Grafana Service**: Fixed s6-rc-compile error caused by improper service type file formatting
- **Container Startup**: Resolved issue preventing services from starting in test-mode
- **Service Integration**: Grafana service now properly integrated with s6-overlay

## 2.5.0 - 2025-01-27

### 🎉 Major Feature: Grafana Added to the Stack

### Added

- **📊 Grafana Integration**: Complete Grafana installation and configuration
- **Dashboard Visualization**: World-class dashboard and monitoring capabilities
- **Prometheus Data Source**: Pre-configured connection to Prometheus metrics
- **Home Assistant Integration**: Full ingress support with nginx proxy
- **Admin Configuration**: Configurable admin password via addon options

### Technical Implementation

- **Grafana v11.3.1**: Latest stable version with modern features
- **SQLite Database**: Lightweight embedded database for addon use
- **Service Integration**: Full s6-overlay service with health checks
- **Port Configuration**: Port 3000 available for direct access (disabled by default)
- **Security**: Secure default configuration with configurable authentication

### Web Interface

- **New Grafana Card**: Added to main dashboard with direct links
- **Health Monitoring**: Built-in health check endpoints
- **Cross-Mode Access**: Works via ingress and direct port access
- **Visual Integration**: Consistent styling with other service cards

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