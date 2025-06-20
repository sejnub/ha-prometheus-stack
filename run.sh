#!/bin/bash

CONFIG_PATH=/data/options.json

# Read configuration from options.json
ALERTMANAGER_RECEIVER=$(jq --raw-output '.alertmanager_receiver' $CONFIG_PATH)
ALERTMANAGER_TO_EMAIL=$(jq --raw-output '.alertmanager_to_email' $CONFIG_PATH)

# Create necessary directories
mkdir -p /etc/alertmanager
mkdir -p /etc/karma
mkdir -p /etc/blackbox_exporter
mkdir -p /data/prometheus
mkdir -p /data/alertmanager

# Create alertmanager.yml
cat > /etc/alertmanager/alertmanager.yml <<EOF
global:
  resolve_timeout: 5m
  smtp_smarthost: 'localhost:25'
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

# Start Alertmanager
echo "Starting Alertmanager..."
/opt/alertmanager/alertmanager \
  --config.file=/etc/alertmanager/alertmanager.yml \
  --storage.path=/data/alertmanager &

# Wait for Alertmanager to be ready
echo "Waiting for Alertmanager to be ready..."
for i in {1..30}; do
  if curl -s http://localhost:9093/-/healthy > /dev/null 2>&1; then
    echo "Alertmanager is ready!"
    break
  fi
  echo "Waiting for Alertmanager... ($i/30)"
  sleep 2
done

# Start Blackbox Exporter
echo "Starting Blackbox Exporter..."
/opt/blackbox_exporter/blackbox_exporter \
  --config.file=/etc/blackbox_exporter/blackbox.yml \
  --web.listen-address=:9115 &

# Wait for Blackbox Exporter to be ready
echo "Waiting for Blackbox Exporter to be ready..."
for i in {1..30}; do
  if curl -s http://localhost:9115/metrics > /dev/null 2>&1; then
    echo "Blackbox Exporter is ready!"
    break
  fi
  echo "Waiting for Blackbox Exporter... ($i/30)"
  sleep 2
done

# Start Prometheus
echo "Starting Prometheus..."
/opt/prometheus/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/data/prometheus \
  --web.console.libraries=/opt/prometheus/console_libraries \
  --web.console.templates=/opt/prometheus/consoles \
  --web.enable-lifecycle &

# Wait for Prometheus to be ready
echo "Waiting for Prometheus to be ready..."
for i in {1..30}; do
  if curl -s http://localhost:9090/-/healthy > /dev/null 2>&1; then
    echo "Prometheus is ready!"
    break
  fi
  echo "Waiting for Prometheus... ($i/30)"
  sleep 2
done

# Start Karma
echo "Starting Karma..."
karma --config.file=/etc/karma/karma.yml
