FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Instalace pouze nezbytných síťových nástrojů
RUN apt-get update && apt-get install -y \
    curl \
    openvpn \
    unzip \
    wireguard \
    iproute2 \
    ca-certificates \
    tinyproxy \
    iptables \
    && rm -rf /var/lib/apt/lists/*

ARG CG_VERSION=1.3.4
ARG DOWNLOAD_URL=https://download.cyberghostvpn.com/linux/cyberghostvpn-ubuntu-22.04-${CG_VERSION}.zip

RUN echo "Stahuji z: ${DOWNLOAD_URL}" && \
    curl -L "${DOWNLOAD_URL}" -o cg.zip && \
    unzip cg.zip && \
    cd cyberghostvpn-ubuntu-* && \
    # MANUÁLNÍ INSTALACE (to, co dělá skript uvnitř):
    # 1. Rozbalíme data.tar.gz, kde je samotná aplikace
    tar xzvf data.tar.gz && \
    # 2. Přesuneme binárku do systémové cesty
    cp usr/bin/cyberghostvpn /usr/bin/ && \
    # 3. Zkopírujeme konfigurační šablony a certifikáty
    mkdir -p /etc/cyberghost /usr/local/share/cyberghost && \
    cp -r usr/local/share/cyberghost/* /usr/local/share/cyberghost/ && \
    # 4. Nastavení práv
    chmod +x /usr/bin/cyberghostvpn && \
    cd .. && rm -rf cg.zip cyberghostvpn-ubuntu-*

# Ověření, že binárka funguje (vypíše verzi)
RUN cyberghostvpn --version || true

# Konfigurace Tinyproxy
RUN sed -i 's/^Allow /#Allow /' /etc/tinyproxy/tinyproxy.conf \
    && echo "Allow 0.0.0.0/0" >> /etc/tinyproxy/tinyproxy.conf

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8888 51820/udp
ENTRYPOINT ["/entrypoint.sh"]
