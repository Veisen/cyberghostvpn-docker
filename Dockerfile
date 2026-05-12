FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
    curl openvpn unzip wireguard wireguard-tools iproute2 ca-certificates tinyproxy iptables \
    && rm -rf /var/lib/apt/lists/*

# Dynamické stažení CyberGhost CLI
ARG DOWNLOAD_URL
RUN if [ -z "$DOWNLOAD_URL" ]; then \
      # Získáme URL a ujistíme se, že je to čistý text bez skrytých znaků
      FETCHED_URL=$(curl -sL "https://www.cyberghostvpn.com/en_US/vpn-for-linux" | \
      grep -oE 'https://download.cyberghostvpn.com/linux/cyberghostvpn-ubuntu-[0-9.]+-1[a-zA-Z0-9.-]*\.zip' | head -n 1); \
      DOWNLOAD_URL=$FETCHED_URL; \
    fi; \
    if [ -z "$DOWNLOAD_URL" ]; then echo "CHYBA: Nepodařilo se najít URL ke stažení!" && exit 1; fi; \
    echo "Stahuji z: $DOWNLOAD_URL" && \
    curl -L "$DOWNLOAD_URL" -o cg.zip && \
    unzip cg.zip && \
    cd cyberghostvpn-ubuntu-* && \
    # Spuštění instalace s vynucením non-interactive módu, pokud je to možné
    DEBIAN_FRONTEND=noninteractive bash install.sh && \
    cd .. && rm -rf cg.zip cyberghostvpn-ubuntu-*

# Konfigurace Tinyproxy
RUN sed -i 's/^Allow /#Allow /' /etc/tinyproxy/tinyproxy.conf \
    && echo "Allow 0.0.0.0/0" >> /etc/tinyproxy/tinyproxy.conf

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Porty: 8888 (Proxy), 51820 (WireGuard UDP)
EXPOSE 8888 51820/udp
ENTRYPOINT ["/entrypoint.sh"]
