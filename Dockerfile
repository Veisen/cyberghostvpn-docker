FROM ubuntu:22.04

# Zamezení interaktivním dotazům
ENV DEBIAN_FRONTEND=noninteractive

# 1. Instalace síťových nástrojů a závislostí
# Instalujeme pouze nástroje pro běh, ne pro kompilaci (DKMS)
RUN apt-get update && apt-get install -y \
    curl \
    openvpn \
    unzip \
    wireguard-tools \
    iproute2 \
    ca-certificates \
    tinyproxy \
    iptables \
    && rm -rf /var/lib/apt/lists/*

# 2. Kopírování tvého nahraného souboru z repozitáře
# Ujisti se, že se soubor v repozitáři jmenuje přesně takto
COPY cyberghostvpn-ubuntu-22.04-1.4.1.zip cg.zip

# 3. Manuální rozbalení a instalace binárky
RUN unzip cg.zip && \
    cd cyberghostvpn-ubuntu-* && \
    # Rozbalíme vnitřní archiv se soubory aplikace
    tar xzvf data.tar.gz && \
    # Kopírování binárky do systému
    cp usr/bin/cyberghostvpn /usr/bin/ && \
    # Vytvoření složek a kopírování certifikátů/šablon
    mkdir -p /etc/cyberghost /usr/local/share/cyberghost && \
    cp -r usr/local/share/cyberghost/* /usr/local/share/cyberghost/ && \
    # Nastavení práv pro spuštění
    chmod +x /usr/bin/cyberghostvpn && \
    # Úklid
    cd .. && rm -rf cg.zip cyberghostvpn-ubuntu-24.04-1.4.1

# 4. Konfigurace Tinyproxy (povolení přístupu zvenčí)
RUN sed -i 's/^Allow /#Allow /' /etc/tinyproxy/tinyproxy.conf && \
    echo "Allow 0.0.0.0/0" >> /etc/tinyproxy/tinyproxy.conf

# 5. Nastavení spouštěcího skriptu
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Porty: 8888 (Proxy), 51820 (WireGuard server)
EXPOSE 8888 51820/udp

ENTRYPOINT ["/entrypoint.sh"]
