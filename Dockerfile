FROM ubuntu:22.04

# Nastavení non-interactive módu pro apt
ENV DEBIAN_FRONTEND=noninteractive

# 1. Instalace kritických prvků pro instalátor CyberGhost (sudo, lsb-release) + zbytek
RUN apt-get update && apt-get install -y \
    curl \
    openvpn \
    unzip \
    wireguard \
    iproute2 \
    ca-certificates \
    tinyproxy \
    iptables \
    sudo \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Definice verze
ARG CG_VERSION=1.3.4
ARG DOWNLOAD_URL=https://download.cyberghostvpn.com/linux/cyberghostvpn-ubuntu-22.04-${CG_VERSION}.zip

# 2. Stažení a OPRAVENÁ instalace
# CyberGhost skript kontroluje, zda běží pod sudo. V Dockeru jsme root, 
# tak mu vytvoříme falešné sudo, pokud by ho vyžadoval.
RUN echo "Stahuji z: ${DOWNLOAD_URL}" && \
    curl -L "${DOWNLOAD_URL}" -o cg.zip && \
    unzip cg.zip && \
    cd cyberghostvpn-ubuntu-* && \
    # Spustíme instalaci a odpovíme 'Y' na všechna potvrzení
    printf "y\ny\n" | bash install.sh && \
    cd .. && rm -rf cg.zip cyberghostvpn-ubuntu-*

# 3. Konfigurace Tinyproxy
RUN sed -i 's/^Allow /#Allow /' /etc/tinyproxy/tinyproxy.conf \
    && echo "Allow 0.0.0.0/0" >> /etc/tinyproxy/tinyproxy.conf

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8888 51820/udp
ENTRYPOINT ["/entrypoint.sh"]
