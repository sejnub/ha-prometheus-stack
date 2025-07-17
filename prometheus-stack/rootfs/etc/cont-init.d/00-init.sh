#!/usr/bin/with-contenv bashio

# Initialize configuration and directories
CONFIG_PATH=/data/options.json

# Create log directories for all services
echo "Creating log directories for stack services..."
mkdir -p /var/log/prometheus
mkdir -p /var/log/alertmanager
mkdir -p /var/log/grafana
mkdir -p /var/log/blackbox
mkdir -p /var/log/karma
mkdir -p /var/log/loki
mkdir -p /var/log/vscode
mkdir -p /var/log/nginx

# Set proper permissions
chmod 755 /var/log/prometheus
chmod 755 /var/log/alertmanager
chmod 755 /var/log/grafana
chmod 755 /var/log/blackbox
chmod 755 /var/log/karma
chmod 755 /var/log/loki
chmod 755 /var/log/vscode
chmod 755 /var/log/nginx

# Create log files if they don't exist
touch /var/log/prometheus/prometheus.log
touch /var/log/alertmanager/alertmanager.log
touch /var/log/grafana/grafana.log
touch /var/log/blackbox/blackbox.log
touch /var/log/karma/karma.log
touch /var/log/loki/loki.log
touch /var/log/vscode/vscode.log

# Set proper permissions for log files
chmod 644 /var/log/prometheus/prometheus.log
chmod 644 /var/log/alertmanager/alertmanager.log
chmod 644 /var/log/grafana/grafana.log
chmod 644 /var/log/blackbox/blackbox.log
chmod 644 /var/log/karma/karma.log
chmod 644 /var/log/loki/loki.log
chmod 644 /var/log/vscode/vscode.log

echo "Log directories and files created successfully"

# Read configuration from options.json
if [ -f $CONFIG_PATH ]; then
    echo "Loading configuration from options.json..."
    ALERTMANAGER_RECEIVER=$(jq --raw-output '.alertmanager_receiver' $CONFIG_PATH)
    ALERTMANAGER_TO_EMAIL=$(jq --raw-output '.alertmanager_to_email' $CONFIG_PATH)
    HOME_ASSISTANT_IP=$(jq --raw-output '.home_assistant_ip' $CONFIG_PATH)
    HOME_ASSISTANT_PORT=$(jq --raw-output '.home_assistant_port' $CONFIG_PATH)
    HOME_ASSISTANT_TOKEN=$(jq --raw-output '.home_assistant_long_lived_token' $CONFIG_PATH)
    SMTP_HOST=$(jq --raw-output '.smtp_host' $CONFIG_PATH)
    SMTP_PORT=$(jq --raw-output '.smtp_port' $CONFIG_PATH)
    LOKI_RETENTION_PERIOD=$(jq --raw-output '.loki_retention_period // "168h"' $CONFIG_PATH)
    LOKI_INGESTION_RATE_MB=$(jq --raw-output '.loki_ingestion_rate_mb // 4' $CONFIG_PATH)
else
    echo "No options.json found, using defaults..."
    # Set defaults if file doesn't exist
    ALERTMANAGER_RECEIVER="default"
    ALERTMANAGER_TO_EMAIL="example@example.com"
    HOME_ASSISTANT_IP="192.168.1.30"
    HOME_ASSISTANT_PORT="8123"
    HOME_ASSISTANT_TOKEN=""
    SMTP_HOST="localhost"
    SMTP_PORT="25"
    LOKI_RETENTION_PERIOD="168h"
    LOKI_INGESTION_RATE_MB="4"
fi

# Create alertmanager.yml
cat > /etc/alertmanager/alertmanager.yml <<EOF
global:
  resolve_timeout: 5m
  smtp_smarthost: '${SMTP_HOST:-localhost}:${SMTP_PORT:-25}'
  smtp_from: 'alertmanager@localhost'

route:
  receiver: '${ALERTMANAGER_RECEIVER}'

receivers:
  - name: '${ALERTMANAGER_RECEIVER}'
    email_configs:
      - to: '${ALERTMANAGER_TO_EMAIL}'
EOF

# Update Loki configuration with user options
if [ -f /etc/loki/loki.yml ]; then
    # Update retention period and ingestion rate in loki.yml
    sed -i "s/retention_period: 0s/retention_period: ${LOKI_RETENTION_PERIOD}/" /etc/loki/loki.yml
    sed -i "s/ingestion_rate_mb: 4/ingestion_rate_mb: ${LOKI_INGESTION_RATE_MB}/" /etc/loki/loki.yml
    echo "Loki configuration updated with retention period: ${LOKI_RETENTION_PERIOD}, ingestion rate: ${LOKI_INGESTION_RATE_MB}MB"
fi

# Create karma.yml configuration
cat > /etc/karma/karma.yml <<EOF
alertmanager:
  servers:
    - name: "default"
      uri: "http://localhost:9093"
      timeout: 10s
      proxy: false
      readonly: false

listen:
  address: "0.0.0.0"
  port: 8080

log:
  level: info
  format: text

labels:
  color:
    static:
      - "@alertmanager=default"
EOF

echo "Configuration initialized successfully" 