#!/usr/bin/with-contenv bashio

# Initialize configuration and directories
CONFIG_PATH=/data/options.json

# Load environment variables if .env file exists (for development/testing)
if [ -f /data/.env ]; then
    echo "Loading environment variables from .env file (development mode)..."
    export $(cat /data/.env | grep -v '^#' | xargs)
fi

# Read configuration from options.json (add-on mode)
if [ -f $CONFIG_PATH ]; then
    echo "Loading configuration from options.json (add-on mode)..."
    ALERTMANAGER_RECEIVER=$(jq --raw-output '.alertmanager_receiver' $CONFIG_PATH)
    ALERTMANAGER_TO_EMAIL=$(jq --raw-output '.alertmanager_to_email' $CONFIG_PATH)
    HOME_ASSISTANT_IP=$(jq --raw-output '.home_assistant_ip' $CONFIG_PATH)
    HOME_ASSISTANT_PORT=$(jq --raw-output '.home_assistant_port' $CONFIG_PATH)
    HOME_ASSISTANT_TOKEN=$(jq --raw-output '.home_assistant_long_lived_token' $CONFIG_PATH)
    SMTP_HOST=$(jq --raw-output '.smtp_host' $CONFIG_PATH)
    SMTP_PORT=$(jq --raw-output '.smtp_port' $CONFIG_PATH)
else
    echo "No options.json found, using environment variables or defaults..."
    # Set defaults if neither file exists
    ALERTMANAGER_RECEIVER=${ALERTMANAGER_RECEIVER:-"default"}
    ALERTMANAGER_TO_EMAIL=${ALERTMANAGER_TO_EMAIL:-"example@example.com"}
    HOME_ASSISTANT_IP=${HOME_ASSISTANT_IP:-"192.168.1.30"}
    HOME_ASSISTANT_PORT=${HOME_ASSISTANT_PORT:-"8123"}
    HOME_ASSISTANT_TOKEN=${HOME_ASSISTANT_LONG_LIVED_TOKEN:-""}
    SMTP_HOST=${SMTP_HOST:-"localhost"}
    SMTP_PORT=${SMTP_PORT:-"25"}
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

# Create karma.yml configuration
cat > /etc/karma/karma.yml <<EOF
alertmanager:
  interval: 1m
  servers:
    - name: "default"
      uri: "http://localhost:9093"
      timeout: 40s
      proxy: false
      readonly: false
      cors:
        credentials: "include"
      tls:
        ca: ""
        cert: ""
        key: ""

listen:
  address: "0.0.0.0"
  port: 8080
  prefix: "/"

log:
  level: "info"
  format: "text"
  timestamp: false
  requests: false

ui:
  refresh: "30s"
  theme: "auto"
  animations: true
  colorTitlebar: false
  hideFiltersWhenIdle: true
  minimalGroupWidth: 420
  alertsPerGroup: 5
  collapseGroups: "collapsedOnMobile"

annotations:
  default:
    hidden: false
  hidden: []
  visible: []
  keep: []
  strip: []
  order: []
  actions: []
  enableInsecureHTML: false

labels:
  keep: []
  strip: []
  order: []
  color:
    static: []
    unique: []
  valueOnly: []
  keep_re: []
  strip_re: []
  valueOnly_re: []

grid:
  sorting:
    order: "startsAt"
    reverse: true
    label: "alertname"
  groupLimit: 40
  auto:
    ignore: []
    order: []

silenceForm:
  strip:
    labels: []
  defaultAlertmanagers: []

receivers:
  keep: []
  strip: []

karma:
  name: "karma"

history:
  enabled: true
  timeout: 20s
  workers: 30

authorization:
  acl:
    silences: ""

filters:
  default: []
EOF

echo "Configuration initialized successfully" 