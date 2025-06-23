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
        jq && \
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

# Copy configuration files
COPY prometheus.yml /etc/prometheus/
COPY blackbox.yml /etc/blackbox_exporter/

# Create necessary directories
RUN mkdir -p /etc/alertmanager /etc/karma /etc/blackbox_exporter /data/prometheus /data/alertmanager

# Copy s6-overlay configuration
COPY rootfs/ /

# Make s6-overlay scripts executable
RUN chmod +x /etc/cont-init.d/00-init.sh && \
    chmod +x /etc/s6-overlay/s6-rc.d/alertmanager/run && \
    chmod +x /etc/s6-overlay/s6-rc.d/alertmanager/up && \
    chmod +x /etc/s6-overlay/s6-rc.d/blackbox-exporter/run && \
    chmod +x /etc/s6-overlay/s6-rc.d/blackbox-exporter/up && \
    chmod +x /etc/s6-overlay/s6-rc.d/prometheus/run && \
    chmod +x /etc/s6-overlay/s6-rc.d/prometheus/up && \
    chmod +x /etc/s6-overlay/s6-rc.d/karma/run && \
    chmod +x /etc/s6-overlay/s6-rc.d/karma/up && \
    chmod +x /etc/s6-overlay/s6-rc.d/user/run
