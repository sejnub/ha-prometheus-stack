# Prometheus Stack Technical Implementation

This document covers the technical implementation details of the Prometheus Stack add-on.

## Service Architecture

The add-on uses s6-overlay for service management. Each component runs as a separate service:

```
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
- `dependencies.d/`: Service dependencies

## NGINX Implementation

NGINX serves as the ingress router with the following configuration:
- Handles all internal service routing
- Manages path-based proxying
- Ensures proper header rewriting
- Handles WebSocket upgrades for real-time features

For user-facing access information, see the main [README.md](../README.md).

## Support

- [Documentation](https://github.com/sejnub/ha-prometheus-stack/wiki)
- [Issue Tracker](https://github.com/sejnub/ha-prometheus-stack/issues)

## License

MIT License - see LICENSE file for details 