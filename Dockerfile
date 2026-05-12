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
    curl -L -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
         -H "Referer: https://www.cyberghostvpn.com/" \
         "${DOWNLOAD_URL}" -o cg.zip && \
    # Kontrola, zda stažený soubor není příliš malý (HTML error page)
    if [ $(stat -c%s cg.zip) -lt 10000 ]; then echo "CHYBA: Stažený soubor je poškozený nebo zablokovaný!" && cat cg.zip && exit 1; fi && \
    unzip cg.zip && \
    cd cyberghostvpn-ubuntu-* && \
    tar xzvf data.tar.gz && \
    cp usr/bin/cyberghostvpn /usr/bin/ && \
    mkdir -p /etc/cyberghost /usr/local/share/cyberghost && \
    cp -r usr/local/share/cyberghost/* /usr/local/share/cyberghost/ && \
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
