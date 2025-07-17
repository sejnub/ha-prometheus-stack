# Prometheus Stack Technical Implementation

This document covers the technical implementation details of the Prometheus Stack add-on.

- [1. Service Architecture](#1-service-architecture)
- [2. Service Dependencies](#2-service-dependencies)
- [3. NGINX Implementation](#3-nginx-implementation)
  - [3.1. Routing Configuration](#31-routing-configuration)
- [4. Data Persistence](#4-data-persistence)
- [5. Configuration Management](#5-configuration-management)
- [6. Development](#6-development)
- [7. Support](#7-support)
- [8. License](#8-license)

## 1. Service Architecture

The add-on uses s6-overlay for service management. Each component runs as a separate service:

```txt
/etc/s6-overlay/s6-rc.d/
├── alertmanager/
├── blackbox-exporter/
├── karma/
├── nginx/
├── prometheus/
└── user/
```

Each service follows a standard structure:

- `run`: Main service script
- `up`: Service initialization
- `type`: Service type definition

## 2. Service Dependencies

The services have the following dependency structure:

- **prometheus**: Depends on `legacy-cont-init` and `blackbox-exporter`
- **alertmanager**: Depends on `legacy-cont-init`
- **karma**: Depends on `alertmanager` and `prometheus`
- **nginx**: No dependencies (starts first)
- **blackbox-exporter**: Depends on `legacy-cont-init`

## 3. NGINX Implementation

NGINX serves as the ingress router with the following configuration:

- Handles all internal service routing
- Manages path-based proxying
- Ensures proper header rewriting
- Handles WebSocket upgrades for real-time features

### 3.1. Routing Configuration

- **Main UI**: `/` → Karma (default interface)
- **Prometheus**: `/prometheus/` → Prometheus web interface
- **Alertmanager**: `/alertmanager/` → Alertmanager web interface
- **Blackbox**: `/blackbox/` → Blackbox Exporter interface

## 4. Data Persistence

The add-on maintains persistent data in:

- `/data/prometheus/`: Time-series database storage
- `/data/alertmanager/`: Alert state and silences
- `/data/nginx/`: NGINX logs and temporary files

## 5. Configuration Management

Configuration files are generated dynamically from add-on options:

- **Prometheus**: `/etc/prometheus/prometheus.yml`
- **Alertmanager**: `/etc/alertmanager/alertmanager.yml`
- **Blackbox**: `/etc/blackbox_exporter/blackbox.yml`
- **Karma**: `/etc/karma/karma.yml`

## 6. Development

For user-facing access information, see the main [README.md](../README.md).

For development and testing instructions, see [test/README.md](../test/README.md).

## 7. Support

- [Documentation](https://github.com/sejnub/ha-prometheus-stack/wiki)
- [Issue Tracker](https://github.com/sejnub/ha-prometheus-stack/issues)

## 8. License

MIT License - see [LICENSE](../LICENSE) file for details
