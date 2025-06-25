ARG BUILD_FROM
FROM ${BUILD_FROM:-ghcr.io/hassio-addons/base:14.2.2}

ENV PROM_VERSION=2.52.0
ENV ALERTMANAGER_VERSION=0.27.0
ENV KARMA_VERSION=v0.116
ENV BLACKBOX_VERSION=0.25.0

# Install required packages
RUN apk add --no-cache \
        bash \
        curl \
        tar \
        wget \
        jq \
        nginx && \
    ARCH="" && \
    ARM_ARCH="" && \
    case `uname -m` in \
        x86_64) ARCH="amd64" ;; \
        aarch64) ARCH="arm64" ;; \
        armv7l) ARCH="armv7" ARM_ARCH="arm" ;; \
    esac && \
    wget https://github.com/prometheus/prometheus/releases/download/v${PROM_VERSION}/prometheus-${PROM_VERSION}.linux-${ARCH}.tar.gz && \
    tar -xzf prometheus-${PROM_VERSION}.linux-${ARCH}.tar.gz && \
    mv prometheus-${PROM_VERSION}.linux-${ARCH} /opt/prometheus && \
    wget https://github.com/prometheus/alertmanager/releases/download/v${ALERTMANAGER_VERSION}/alertmanager-${ALERTMANAGER_VERSION}.linux-${ARCH}.tar.gz && \
    tar -xzf alertmanager-${ALERTMANAGER_VERSION}.linux-${ARCH}.tar.gz && \
    mv alertmanager-${ALERTMANAGER_VERSION}.linux-${ARCH} /opt/alertmanager && \
    wget https://github.com/prymitive/karma/releases/download/${KARMA_VERSION}/karma-linux-${ARCH:-$ARM_ARCH}.tar.gz && \
    tar -xzf karma-linux-${ARCH:-$ARM_ARCH}.tar.gz && \
    mv karma-linux-${ARCH:-$ARM_ARCH} /usr/local/bin/karma && \
    wget https://github.com/prometheus/blackbox_exporter/releases/download/v${BLACKBOX_VERSION}/blackbox_exporter-${BLACKBOX_VERSION}.linux-${ARCH}.tar.gz && \
    tar -xzf blackbox_exporter-${BLACKBOX_VERSION}.linux-${ARCH}.tar.gz && \
    mv blackbox_exporter-${BLACKBOX_VERSION}.linux-${ARCH} /opt/blackbox_exporter && \
    rm -rf *.tar.gz && \
    apk del wget tar && \
    rm -rf /var/cache/apk/*

# Create required directories for persistent configs
RUN mkdir -p /config/prometheus /config/alertmanager /config/blackbox_exporter /config/karma /config/nginx && \
    mkdir -p /data/prometheus /data/alertmanager && \
    mkdir -p /etc/nginx/http.d && \
    rm -f /etc/nginx/http.d/default.conf

# Copy default configuration files to persistent locations
COPY prometheus.yml /config/prometheus/prometheus.yml
COPY blackbox.yml /config/blackbox_exporter/blackbox.yml

# Create symbolic links to persistent configs
RUN ln -sf /config/prometheus/prometheus.yml /etc/prometheus/prometheus.yml && \
    ln -sf /config/blackbox_exporter/blackbox.yml /etc/blackbox_exporter/blackbox.yml && \
    ln -sf /config/alertmanager/alertmanager.yml /etc/alertmanager/alertmanager.yml && \
    ln -sf /config/karma/karma.yml /etc/karma/karma.yml && \
    ln -sf /config/nginx/nginx.conf /etc/nginx/nginx.conf

# Copy root filesystem
COPY rootfs/ /

# Set permissions
RUN chmod +x /etc/cont-init.d/00-init.sh && \
    chmod +x /etc/s6-overlay/s6-rc.d/*/run && \
    find /etc/s6-overlay/s6-rc.d -name finish -type f -exec chmod +x {} \;
