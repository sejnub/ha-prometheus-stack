# Prometheus Stack Add-on for Home Assistant

This add-on provides a complete monitoring stack for Home Assistant, including Prometheus, Alertmanager, Karma (Alert Dashboard), and Blackbox Exporter.

## Features

- **Prometheus**: Time series database and monitoring system
- **Alertmanager**: Alert handling and routing
- **Karma**: Alert dashboard with a modern UI
- **Blackbox Exporter**: Endpoint monitoring
- **Ingress Support**: All UIs accessible through Home Assistant

## Web Interfaces

All interfaces are available through Home Assistant's ingress feature:

- **Karma**: Main dashboard (default interface)
- **Prometheus**: `/prometheus/` path
- **Alertmanager**: `/alertmanager/` path
- **Blackbox**: `/blackbox/` path

## Configuration

### Add-on Configuration

```yaml
alertmanager_receiver: "default"
alertmanager_to_email: "your@email.com"
home_assistant_url: "http://supervisor/core"
home_assistant_token: "your_long_lived_token"
blackbox_targets:
  - name: "Home Assistant"
    url: "http://supervisor/core"
```

### Option Descriptions

- `alertmanager_receiver`: Name of the default alert receiver
- `alertmanager_to_email`: Email address for alert notifications
- `home_assistant_url`: URL of your Home Assistant instance
- `home_assistant_token`: Long-lived access token for Home Assistant
- `blackbox_targets`: List of endpoints to monitor
  - `name`: Display name for the target
  - `url`: URL to monitor

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

## Development

### Building Locally

```bash
# From the repository root
docker build \
  --build-arg BUILD_FROM="ghcr.io/hassio-addons/base:14.2.2" \
  -t prometheus-stack .
```

### Testing

Use the provided test scripts in the `test/` directory:
```bash
./test/build-test.sh  # Build and test the add-on
./test/cleanup.sh     # Clean up test artifacts
```

## Support

- [Documentation](https://github.com/sejnub/ha-prometheus-stack/wiki)
- [Issue Tracker](https://github.com/sejnub/ha-prometheus-stack/issues)

## License

MIT License - see LICENSE file for details 