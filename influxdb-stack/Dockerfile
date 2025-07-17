ARG BUILD_FROM
FROM ${BUILD_FROM:-ghcr.io/hassio-addons/base:14.2.2}

ENV INFLUXDB_VERSION=2.7.12
ENV CODESERVER_VERSION=4.19.1
ENV GRAFANA_VERSION=11.3.1

# Install required packages
RUN apk add --no-cache \
        bash \
        curl \
        tar \
        wget \
        jq \
        nginx \
        nodejs \
        npm \
        git \
        python3 \
        py3-pip && \
    ARCH="" && \
    case `uname -m` in \
        x86_64) ARCH="amd64" ;; \
        aarch64) ARCH="arm64" ;; \
        *) echo "Unsupported architecture: $(uname -m)" && exit 1 ;; \
    esac && \
    wget https://dl.influxdata.com/influxdb/releases/v${INFLUXDB_VERSION}/influxdb2-${INFLUXDB_VERSION}_linux_${ARCH}.tar.gz && \
    tar -xzf influxdb2-${INFLUXDB_VERSION}_linux_${ARCH}.tar.gz && \
    mv influxdb2-${INFLUXDB_VERSION} /opt/influxdb && \
    wget https://github.com/coder/code-server/releases/download/v${CODESERVER_VERSION}/code-server-${CODESERVER_VERSION}-linux-${ARCH}.tar.gz && \
    tar -xzf code-server-${CODESERVER_VERSION}-linux-${ARCH}.tar.gz && \
    mv code-server-${CODESERVER_VERSION}-linux-${ARCH} /opt/code-server && \
    wget https://dl.grafana.com/oss/release/grafana-${GRAFANA_VERSION}.linux-${ARCH}.tar.gz && \
    tar -xzf grafana-${GRAFANA_VERSION}.linux-${ARCH}.tar.gz && \
    mv grafana-v${GRAFANA_VERSION} /opt/grafana && \
    rm -rf *.tar.gz && \
    apk del wget tar && \
    rm -rf /var/cache/apk/*

# Copy configuration files
COPY grafana.ini /etc/grafana/

# Create required directories
RUN mkdir -p /etc/influxdb /etc/grafana /etc/grafana/provisioning/datasources /etc/grafana/provisioning/dashboards /data/influxdb /data/grafana && \
    mkdir -p /etc/nginx/http.d && \
    mkdir -p /opt/code-server/data /opt/code-server/extensions /opt/code-server/data/logs && \
    mkdir -p /etc/.vscode && \
    rm -f /etc/nginx/http.d/default.conf

# Copy root filesystem
COPY rootfs/ /
COPY rootfs/etc/.vscode /etc/.vscode

# Inject version from config.json into HTML
COPY config.json /tmp/config.json
RUN VERSION=$(jq -r '.version' /tmp/config.json) && \
    sed -i "s/__VERSION__/$VERSION/g" /etc/nginx/html/index.html && \
    rm /tmp/config.json

# Set permissions
RUN chmod +x /etc/cont-init.d/00-init.sh && \
    chmod +x /etc/s6-overlay/s6-rc.d/*/run && \
    find /etc/s6-overlay/s6-rc.d -name finish -type f -exec chmod +x {} \; && \
    chmod -R 755 /etc/.vscode && \
    chmod +x /usr/local/bin/vscode-toggle && \
    chmod +x /usr/local/bin/vscode-api-server && \
    chmod +x /usr/local/bin/grafana-api-server

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8086/health || exit 1

# Expose ports
EXPOSE 8086 3000 8443 80
