#!/usr/bin/with-contenv bashio

# Initialize configuration and directories
CONFIG_PATH=/data/options.json

# Read configuration from options.json
if [ -f $CONFIG_PATH ]; then
    echo "Loading configuration from options.json..."
    INFLUXDB_ORG=$(jq --raw-output '.influxdb_org' $CONFIG_PATH)
    INFLUXDB_BUCKET=$(jq --raw-output '.influxdb_bucket' $CONFIG_PATH)
    INFLUXDB_USERNAME=$(jq --raw-output '.influxdb_username' $CONFIG_PATH)
    INFLUXDB_PASSWORD=$(jq --raw-output '.influxdb_password' $CONFIG_PATH)
    INFLUXDB_TOKEN=$(jq --raw-output '.influxdb_token' $CONFIG_PATH)
    HOME_ASSISTANT_URL=$(jq --raw-output '.home_assistant_url' $CONFIG_PATH)
    HOME_ASSISTANT_TOKEN=$(jq --raw-output '.home_assistant_token' $CONFIG_PATH)
    GRAFANA_ADMIN_PASSWORD=$(jq --raw-output '.grafana_admin_password' $CONFIG_PATH)
else
    echo "No options.json found, using defaults..."
    # Set defaults if file doesn't exist
    INFLUXDB_ORG="my-org"
    INFLUXDB_BUCKET="my-bucket"
    INFLUXDB_USERNAME="admin"
    INFLUXDB_PASSWORD="admin123"
    INFLUXDB_TOKEN=""
    HOME_ASSISTANT_URL="http://supervisor/core"
    HOME_ASSISTANT_TOKEN=""
    GRAFANA_ADMIN_PASSWORD="admin"
fi

# Create InfluxDB configuration
echo "Creating InfluxDB configuration..."
mkdir -p /data/influxdb

# Update Grafana datasource configuration with actual values
echo "Updating Grafana datasource configuration..."
sed -i "s/my-org/${INFLUXDB_ORG}/g" /etc/grafana/provisioning/datasources/influxdb.yml
sed -i "s/my-bucket/${INFLUXDB_BUCKET}/g" /etc/grafana/provisioning/datasources/influxdb.yml
sed -i "s/my-token/${INFLUXDB_TOKEN}/g" /etc/grafana/provisioning/datasources/influxdb.yml

# Update Grafana admin password
sed -i "s/admin_password = admin/admin_password = ${GRAFANA_ADMIN_PASSWORD}/g" /etc/grafana/grafana.ini

echo "Configuration initialized successfully" 