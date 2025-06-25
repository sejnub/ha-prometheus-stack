#!/usr/bin/with-contenv bashio

# Initialize configuration and directories
CONFIG_PATH=/data/options.json

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
fi

# Create alertmanager.yml in persistent location
cat > /config/alertmanager/alertmanager.yml <<EOF
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

# Create karma.yml configuration in persistent location
cat > /config/karma/karma.yml <<EOF
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

# Create nginx.conf in persistent location if it doesn't exist
if [ ! -f /config/nginx/nginx.conf ]; then
    cp /etc/nginx/nginx.conf /config/nginx/nginx.conf
fi

echo "Configuration initialized successfully in persistent locations"
echo "All configuration files are now editable in the config directory" 