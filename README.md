# Prometheus Stack Add-on for Home Assistant

A comprehensive monitoring stack for Home Assistant that includes Prometheus, Alertmanager, Karma, and Blackbox Exporter in a single add-on.

## What is this?

This add-on provides a complete monitoring solution for your Home Assistant environment:

- **Prometheus**: Time-series database for metrics collection and storage
- **Alertmanager**: Alert routing and notification management
- **Karma**: Modern web UI for alert management and visualization
- **Blackbox Exporter**: External service monitoring via HTTP and TCP probes

## Features

- **Multi-architecture support**: Works on `amd64`, `arm64`, and `armv7`
- **Email notifications**: Configurable alert notifications via email
- **Ingress support**: Access Karma UI directly through Home Assistant
- **Dynamic configuration**: Alertmanager configures automatically from add-on settings
- **Persistent storage**: Data survives add-on updates and restarts
- **Home Assistant integration**: Scrapes Home Assistant metrics automatically
- **External monitoring**: Monitors Home Assistant add-ons and services via HTTP/TCP probes
- **Comprehensive coverage**: Monitors 50+ common Home Assistant add-ons out of the box

## Installation

### Prerequisites
- Home Assistant (Supervisor or Core)
- Add-on store access

### Installation Steps
1. In Home Assistant, go to **Settings** → **Add-ons** → **Add-on Store**
2. Click the three dots in the top right and select **Repositories**
3. Add this repository URL: `https://github.com/yourusername/ha-prometheus-stack`
4. Find "Prometheus Stack" in the add-on store
5. Click **Install**

## Configuration

### Basic Configuration
The add-on can be configured through the Home Assistant UI:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `alertmanager_receiver` | string | `default` | Name of the alert receiver |
| `alertmanager_to_email` | email | `example@example.com` | Email address for notifications |
| `monitor_home_assistant` | boolean | `true` | Monitor Home Assistant Core |
| `monitor_supervisor` | boolean | `true` | Monitor Home Assistant Supervisor |
| `monitor_addons` | boolean | `true` | Monitor Home Assistant add-ons |
| `custom_targets` | list | `[]` | Additional monitoring targets |

### Advanced Configuration
You can also configure the add-on using YAML in your `configuration.yaml`:

```yaml
addons:
  prometheus_stack:
    alertmanager_receiver: "home-alerts"
    alertmanager_to_email: "your-email@example.com"
    monitor_home_assistant: true
    monitor_supervisor: true
    monitor_addons: true
    custom_targets:
      - "http://your-custom-service:8080"
      - "your-custom-db:5432"
```

## Access

Once installed and started, you can access the services at:

- **Prometheus**: `http://your-ha-ip:9090`
- **Alertmanager**: `http://your-ha-ip:9093`
- **Blackbox Exporter**: `http://your-ha-ip:9115`
- **Karma UI**: Through Home Assistant Ingress (no additional port needed)

### Ingress Access
The Karma UI is available through Home Assistant's ingress system:
1. Go to **Settings** → **Add-ons** → **Prometheus Stack**
2. Click **OPEN WEB UI**
3. This opens Karma in your Home Assistant interface

## Monitoring Home Assistant

The add-on automatically scrapes Home Assistant metrics from:
- **Target**: `a0d7b954-homeassistant:8123`
- **Interval**: 15 seconds
- **Metrics**: All available Home Assistant metrics

### Available Metrics
- System performance
- Entity states
- Automation triggers
- Integration status
- And more...

## External Service Monitoring

The add-on includes Blackbox Exporter for comprehensive external monitoring:

### HTTP Monitoring
Monitors web interfaces and APIs for:
- Home Assistant Core and API
- Media servers (Plex, Jellyfin, Emby)
- Download clients (SABnzbd, qBittorrent, Transmission)
- Media management (Sonarr, Radarr, Lidarr, Readarr)
- Network tools (Pi-hole, AdGuard, Traefik)
- Development tools (Node-RED, ESPHome, Zigbee2MQTT)
- And 30+ more add-ons

### TCP Monitoring
Monitors network services for:
- Databases (MariaDB, PostgreSQL, Redis, InfluxDB)
- MQTT brokers (Mosquitto)
- File sharing (Samba, FTP, rsync)
- VPN services (WireGuard)
- SSH access

### Blackbox Exporter Endpoints
- **Metrics**: `http://localhost:9115/metrics`
- **Probe Example**: `http://localhost:9115/probe?target=google.com&module=http_2xx`
- **Health Check**: `http://localhost:9115/-/healthy`

## Alert Configuration

### Email Notifications
The add-on automatically configures email notifications based on your settings:

```yaml
# Example alertmanager.yml (auto-generated)
global:
  resolve_timeout: 5m

route:
  receiver: 'your-receiver-name'

receivers:
  - name: 'your-receiver-name'
    email_configs:
      - to: 'your-email@example.com'
```

### Creating Alerts
You can create custom alerts by adding them to your Prometheus configuration or through the Prometheus web interface.

## Development

### Local Testing
If you want to test this add-on locally before installing:

```bash
# Clone the repository
git clone https://github.com/yourusername/ha-prometheus-stack.git
cd ha-prometheus-stack

# Run tests (requires Docker Desktop)
./test/build-test.sh
./test/health-check.sh
./test/cleanup.sh
```

See the [Testing Guide](test/README.md) for detailed testing instructions.

### Building from Source
```bash
# Build the add-on image
docker build -t prometheus-stack .

# Run locally
docker run -d \
  --name prometheus-stack-test \
  -p 9090:9090 -p 9093:9093 -p 8080:8080 -p 9115:9115 \
  -v $(pwd)/test-data:/data \
  prometheus-stack
```

## File Structure

```
ha-prometheus-stack/
├── README.md              # This file
├── Dockerfile             # Multi-architecture build
├── run.sh                 # Startup script
├── config.json            # Add-on configuration
├── prometheus.yml         # Prometheus configuration
├── alertmanager.yml       # Alertmanager configuration
├── blackbox.yml           # Blackbox Exporter configuration
└── test/                  # Testing tools
    ├── README.md          # Testing guide
    ├── build-test.sh      # Build and test script
    ├── health-check.sh    # Health verification
    ├── test-config.sh     # Configuration testing
    ├── monitor.sh         # Resource monitoring
    ├── cleanup.sh         # Environment cleanup
    └── docker-compose.dev.yml # Development environment
```

## Troubleshooting

### Common Issues

1. **Add-on won't start**
   - Check the logs in Home Assistant
   - Verify Docker is running
   - Ensure ports are not in use

2. **Can't access web interfaces**
   - Check if the add-on is running
   - Verify port mappings in Home Assistant
   - Try accessing through ingress for Karma

3. **Email notifications not working**
   - Verify email configuration in add-on settings
   - Check Alertmanager logs
   - Test email connectivity

4. **No metrics appearing**
   - Verify Home Assistant is accessible
   - Check Prometheus targets page
   - Review scrape configuration

5. **Blackbox Exporter not responding**
   - Check if port 9115 is accessible
   - Verify Blackbox Exporter is running
   - Check container logs for errors

### Logs
View logs in Home Assistant:
1. Go to **Settings** → **Add-ons** → **Prometheus Stack**
2. Click **Logs** tab

Or via SSH:
```bash
docker logs addon_local_prometheus_stack
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly using the provided test scripts
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Prometheus](https://prometheus.io/) - Monitoring system
- [Alertmanager](https://prometheus.io/docs/alerting/latest/alertmanager/) - Alert routing
- [Karma](https://github.com/prymitive/karma) - Alert dashboard
- [Home Assistant](https://www.home-assistant.io/) - Home automation platform

## Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/ha-prometheus-stack/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/ha-prometheus-stack/discussions)
- **Documentation**: [Wiki](https://github.com/yourusername/ha-prometheus-stack/wiki)

---

**Note**: This add-on is designed for Home Assistant environments. For production deployments, consider using dedicated monitoring infrastructure. 