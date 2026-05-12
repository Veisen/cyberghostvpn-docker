FROM ubuntu:22.04

# Zamezení interaktivním dotazům
ENV DEBIAN_FRONTEND=noninteractive

# 1. Instalace síťových nástrojů
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

# 2. Kopírování tvého ZIPu z repozitáře
COPY cyberghostvpn-ubuntu-22.04-1.4.1.zip cg.zip

# 3. Manuální instalace (přizpůsobená verzi 1.4.1)
RUN unzip cg.zip && \
    # Vstoupíme do složky, která vznikla po unzipu
    cd cyberghostvpn-ubuntu-22.04-1.4.1 && \
    # Kopírování hlavní binárky (podle logu je ve složce cyberghost/)
    cp cyberghost/cyberghostvpn /usr/bin/ && \
    # Vytvoření konfiguračních složek
    mkdir -p /etc/cyberghost /usr/local/share/cyberghost && \
    # Kopírování certifikátů a pomocných souborů
    cp -r cyberghost/* /usr/local/share/cyberghost/ && \
    # Nastavení práv
    chmod +x /usr/bin/cyberghostvpn && \
    # Úklid
    cd .. && rm -rf cg.zip cyberghostvpn-ubuntu-22.04-1.4.1

# 4. Konfigurace Tinyproxy
RUN sed -i 's/^Allow /#Allow /' /etc/tinyproxy/tinyproxy.conf && \
    echo "Allow 0.0.0.0/0" >> /etc/tinyproxy/tinyproxy.conf

# 5. Nastavení spouštěcího skriptu
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8888 51820/udp

ENTRYPOINT ["/entrypoint.sh"]
