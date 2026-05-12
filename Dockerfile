FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Instalace závislostí včetně lsb-release a sudo (nutné pro install.sh)
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

ARG CG_VERSION=1.3.4
ARG DOWNLOAD_URL=https://download.cyberghostvpn.com/linux/cyberghostvpn-ubuntu-22.04-${CG_VERSION}.zip

RUN echo "Stahuji z: ${DOWNLOAD_URL}" && \
    curl -L "${DOWNLOAD_URL}" -o cg.zip && \
    unzip cg.zip && \
    cd cyberghostvpn-ubuntu-* && \
    # KLÍČOVÉ ÚPRAVY:
    # 1. Vytvoříme prázdný soubor, aby si skript myslel, že systemd existuje
    touch /bin/systemctl && chmod +x /bin/systemctl && \
    # 2. Spustíme instalátor, potvrdíme vstupy a ignorujeme exit code (|| true)
    #    Instalátor často hodí chybu na konci, i když binárku už nainstaloval.
    printf "y\ny\n" | bash install.sh || true && \
    # 3. Kontrola, zda binárka skutečně existuje (pokud ne, build selže tady)
    ls /usr/bin/cyberghostvpn && \
    cd .. && rm -rf cg.zip cyberghostvpn-ubuntu-*

# Konfigurace Tinyproxy
RUN sed -i 's/^Allow /#Allow /' /etc/tinyproxy/tinyproxy.conf \
    && echo "Allow 0.0.0.0/0" >> /etc/tinyproxy/tinyproxy.conf

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8888 51820/udp
ENTRYPOINT ["/entrypoint.sh"]
