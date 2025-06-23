# Prometheus Stack v{VERSION}

## 🚀 What's New

- **New Features:**
  - [Feature 1]
  - [Feature 2]
  
- **Improvements:**
  - [Improvement 1]
  - [Improvement 2]
  
- **Bug Fixes:**
  - [Bug fix 1]
  - [Bug fix 2]

## 📋 Installation

### Via HACS (Recommended)
1. In Home Assistant, go to **Settings** → **Add-ons** → **Add-on Store**
2. Click the three dots in the top right and select **Repositories**
3. Add this repository URL: `https://github.com/yourusername/ha-prometheus-stack`
4. Find "Prometheus Stack" in the add-on store
5. Click **Install**

### Manual Installation
1. Download the latest release
2. Extract to your Home Assistant add-ons directory
3. Restart Home Assistant
4. Install via Add-on Store

## 🔧 Configuration

The add-on can be configured through the Home Assistant UI:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `alertmanager_receiver` | string | `default` | Name of the alert receiver |
| `alertmanager_to_email` | email | `example@example.com` | Email address for notifications |
| `monitor_home_assistant` | boolean | `true` | Monitor Home Assistant Core |
| `monitor_supervisor` | boolean | `true` | Monitor Home Assistant Supervisor |
| `monitor_addons` | boolean | `true` | Monitor Home Assistant add-ons |
| `custom_targets` | list | `[]` | Additional monitoring targets |

## 📊 Features

- **Prometheus**: Time-series database for metrics collection
- **Alertmanager**: Alert routing and notification management
- **Karma**: Modern web UI for alert management
- **Blackbox Exporter**: External service monitoring
- **Multi-architecture support**: Works on amd64, arm64, and armv7
- **Ingress support**: Access Karma UI through Home Assistant
- **Pre-built Grafana dashboards**: Ready-to-use monitoring dashboards

## 🔗 Access URLs

Once installed and started:
- **Prometheus**: `http://your-ha-ip:9090`
- **Alertmanager**: `http://your-ha-ip:9093`
- **Blackbox Exporter**: `http://your-ha-ip:9115`
- **Karma UI**: Through Home Assistant Ingress

## 📝 Changelog

### v{VERSION}
- Initial release
- [List of changes]

## 🐛 Known Issues

- [Issue 1]
- [Issue 2]

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/ha-prometheus-stack/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/ha-prometheus-stack/discussions)

## 📄 License

This project is licensed under the MIT License. 