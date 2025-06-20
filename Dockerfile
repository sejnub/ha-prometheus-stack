ARG BUILD_FROM
FROM ${BUILD_FROM}

ENV PROM_VERSION=2.52.0
ENV ALERTMANAGER_VERSION=0.27.0
ENV KARMA_VERSION=v0.116

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
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
    rm -rf *.tar.gz && \
    apt-get purge -y --auto-remove curl wget tar && \
    rm -rf /var/lib/apt/lists/*

COPY run.sh /
COPY prometheus.yml /etc/prometheus/

RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
