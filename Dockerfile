FROM ubuntu:22.04

# Instalace závislostí
RUN apt-get update && apt-get install -y \
    curl openvpn unzip wireguard iproute2 ca-certificates tinyproxy iptables \
    && rm -rf /var/lib/apt/lists/*

# Definujeme verzi jako ARG, kterou lze přebít při buildu
ARG CG_VERSION=1.3.4
ARG DOWNLOAD_URL=https://download.cyberghostvpn.com/linux/cyberghostvpn-ubuntu-22.04-${CG_VERSION}.zip

RUN echo "Stahuji z: ${DOWNLOAD_URL}" && \
    curl -L "${DOWNLOAD_URL}" -o cg.zip && \
    unzip cg.zip && \
    cd cyberghostvpn-ubuntu-* && \
    # Instalace CyberGhostu vyžaduje potvrzení, install.sh v sobě má 'read'
    # Použijeme 'yes', abychom automaticky vše potvrdili
    yes | bash install.sh && \
    cd .. && rm -rf cg.zip cyberghostvpn-ubuntu-*

# Konfigurace Tinyproxy
RUN sed -i 's/^Allow /#Allow /' /etc/tinyproxy/tinyproxy.conf \
    && echo "Allow 0.0.0.0/0" >> /etc/tinyproxy/tinyproxy.conf

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8888 51820/udp
ENTRYPOINT ["/entrypoint.sh"]
