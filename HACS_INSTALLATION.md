# HACS Installation Guide

## Prerequisites

1. **Home Assistant** (Supervisor or Core) installed
2. **HACS** (Home Assistant Community Store) installed
   - [HACS Installation Guide](https://hacs.xyz/docs/installation/installation/)

## Installation Steps

### Step 1: Add Repository to HACS

1. Open Home Assistant
2. Go to **Settings** → **Add-ons** → **Add-on Store**
3. Click the three dots (⋮) in the top right corner
4. Select **Repositories**
5. Click **Add** button
6. Enter the repository URL: `https://github.com/yourusername/ha-prometheus-stack`
7. Select **Add-on** as the category
8. Click **Add**

### Step 2: Install the Add-on

1. In the Add-on Store, search for **"Prometheus Stack"**
2. Click on the **Prometheus Stack** add-on
3. Click **Install**
4. Wait for the installation to complete

### Step 3: Configure the Add-on

1. After installation, click **Configuration**
2. Configure the following options:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `alertmanager_receiver` | string | `default` | Name of the alert receiver |
| `alertmanager_to_email` | email | `example@example.com` | Email address for notifications |
| `monitor_home_assistant` | boolean | `true` | Monitor Home Assistant Core |
| `monitor_supervisor` | boolean | `true` | Monitor Home Assistant Supervisor |
| `monitor_addons` | boolean | `true` | Monitor Home Assistant add-ons |
| `custom_targets` | list | `[]` | Additional monitoring targets |

3. Click **Save**

### Step 4: Start the Add-on

1. Click **Start** to launch the add-on
2. Wait for all services to start (this may take a few minutes)
3. Check the **Logs** tab to ensure everything is running correctly

## Accessing the Services

Once the add-on is running, you can access:

- **Prometheus**: `http://your-ha-ip:9090`
- **Alertmanager**: `http://your-ha-ip:9093`
- **Blackbox Exporter**: `http://your-ha-ip:9115`
- **Karma UI**: Click **OPEN WEB UI** in the add-on interface

## Grafana Dashboards

The add-on includes pre-configured Grafana dashboards:

1. Install the **Grafana** add-on in Home Assistant
2. Configure **Prometheus** as a data source in Grafana
3. Import the dashboard JSON files from the `dashboards/` directory

## Troubleshooting

### Add-on won't start
- Check the logs in the add-on interface
- Verify Docker is running
- Ensure ports are not in use

### Can't access web interfaces
- Check if the add-on is running
- Verify port mappings in Home Assistant
- Try accessing through ingress for Karma

### No metrics appearing
- Verify Home Assistant is accessible
- Check Prometheus targets page
- Review scrape configuration

## Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/ha-prometheus-stack/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/ha-prometheus-stack/discussions)
- **Documentation**: [Wiki](https://github.com/yourusername/ha-prometheus-stack/wiki)

## Updates

HACS will automatically notify you when updates are available:

1. Go to **Settings** → **Add-ons** → **Add-on Store**
2. Look for the **Prometheus Stack** add-on
3. Click **Update** if available
4. Restart the add-on after update

## Uninstallation

To remove the add-on:

1. Go to **Settings** → **Add-ons** → **Prometheus Stack**
2. Click **Uninstall**
3. Confirm the uninstallation
4. The add-on and all its data will be removed 