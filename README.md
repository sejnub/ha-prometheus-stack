# 🔍 Prometheus Stack Add-on for Home Assistant

A comprehensive monitoring stack for Home Assistant that includes Prometheus, Alertmanager, Karma, and Blackbox Exporter in a single add-on.


## Remember

- It must run equally well in the following modes

  - **Test mode**: When started on the development computer
  - **Github Mode**: When Run by Github actions
  - **Addon Mode**: When run as a home Assistant Add-On

- All waits must be loops that have a minimal fixed time (0.5 seconds) and then check what they are waiting for

- Question: Is it enough that the "build"-script relies on the folders "dependencies.d" or must each service wait for the previous one really answering



## 1. 📦 What is this?

This add-on provides a complete monitoring solution for your Home Assistant environment:

- **Prometheus**: Time-series database for metrics collection and storage
- **Alertmanager**: Alert routing and notification management
- **Karma**: Modern web UI for alert management and visualization
- **Blackbox Exporter**: External service monitoring via HTTP and TCP probes


## 2. ⭐ Key Features

- **Multi-architecture**: Works on `amd64`, `arm64`, and `armv7`
- **Email Alerts**: Configurable alert notifications via email
- **Ingress Support**: Access all UIs directly through Home Assistant
- **Dynamic Config**: Automatic configuration from add-on settings
- **Data Persistence**: Survives add-on updates and restarts
- **HA Integration**: Automatic Home Assistant metrics collection
- **Pre-built Dashboards**: Ready-to-use Grafana dashboards

## 3. 🚀 Installation

### 3.1. Prerequisites
- Home Assistant (Supervisor or Core)
- Add-on store access

### 3.2. Steps
1. In Home Assistant, go to **Settings** → **Add-ons** → **Add-on Store**
2. Click the three dots in the top right and select **Repositories**
3. Add this repository URL: `https://github.com/sejnub/ha-prometheus-stack`
4. Find "Prometheus Stack" in the add-on store
5. Click **Install**

## 4. ⚙️ Configuration

### 4.1. Add-on Configuration

```yaml
alertmanager_receiver: "default"
alertmanager_to_email: "your@email.com"
home_assistant_url: "http://supervisor/core"
home_assistant_token: "your_long_lived_token"
blackbox_targets:
  - name: "Home Assistant"
    url: "http://supervisor/core"
```

### 4.2. Option Descriptions

- `alertmanager_receiver`: Name of the default alert receiver
- `alertmanager_to_email`: Email address for alert notifications
- `home_assistant_url`: URL of your Home Assistant instance
- `home_assistant_token`: Long-lived access token for Home Assistant
- `blackbox_targets`: List of endpoints to monitor
  - `name`: Display name for the target
  - `url`: URL to monitor

## 5. 🌐 Access

All services are accessible through Home Assistant's ingress feature:

- **Karma UI**: Through Home Assistant Ingress (default interface)
- **Prometheus**: Through `/prometheus/` path
- **Alertmanager**: Through `/alertmanager/` path
- **Blackbox Exporter**: Through `/blackbox/` path

No additional port configuration is needed - everything works through Home Assistant's ingress system.

For technical implementation details, see [prometheus-stack/README.md](prometheus-stack/README.md).

## 6. 📊 Monitoring

### 6.1. Home Assistant Metrics
The add-on automatically collects:
- System performance metrics
- Entity state information
- Automation execution data
- Integration status
- And more...

### 6.2. External Service Monitoring
Built-in monitoring for:
- Home Assistant services
- Media servers and clients
- Network tools and services
- Development tools
- Database systems
- Network protocols

For detailed monitoring capabilities and dashboard setup, see [dashboards/README.md](dashboards/README.md).

## 7. ⚡ Alert Configuration

### 7.1. Email Notifications
The add-on automatically configures email notifications:

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

### 7.2. Custom Alerts
Create custom alerts through:
- Prometheus configuration
- Prometheus web interface

## 8. 🛠️ Development and Testing

For development and testing instructions, see [test/README.md](test/README.md).

## 9. 💬 Support

- [Documentation](https://github.com/sejnub/ha-prometheus-stack/wiki)
- [Issue Tracker](https://github.com/sejnub/ha-prometheus-stack/issues)

## 10. 📄 License

MIT License - see LICENSE file for details 