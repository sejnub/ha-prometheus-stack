#!/usr/bin/with-contenv bash

CONFIG_PATH=/data/options.json

# Read configuration from options.json
ALERTMANAGER_RECEIVER=$(jq --raw-output '.alertmanager_receiver' $CONFIG_PATH)
ALERTMANAGER_TO_EMAIL=$(jq --raw-output '.alertmanager_to_email' $CONFIG_PATH)

# Create alertmanager.yml
cat > /etc/alertmanager/alertmanager.yml <<EOF
global:
  resolve_timeout: 5m

route:
  receiver: '${ALERTMANAGER_RECEIVER}'

receivers:
  - name: '${ALERTMANAGER_RECEIVER}'
    email_configs:
      - to: '${ALERTMANAGER_TO_EMAIL}'
EOF

mkdir -p /data/prometheus
mkdir -p /data/alertmanager

/opt/alertmanager/alertmanager \
  --config.file=/etc/alertmanager/alertmanager.yml \
  --storage.path=/data/alertmanager &

/opt/prometheus/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/data/prometheus \
  --web.console.libraries=/opt/prometheus/console_libraries \
  --web.console.templates=/opt/prometheus/consoles \
  --web.enable-lifecycle &

karma --listen=0.0.0.0:8080
