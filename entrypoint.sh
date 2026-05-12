#!/bin/bash
set -e

# 1. Kontrola proměnných pro CyberGhost
if [ -z "$CG_USERNAME" ] || [ -z "$CG_PASSWORD" ]; then
    echo "CHYBA: CG_USERNAME a CG_PASSWORD jsou povinné!"
    exit 1
fi

# 2. Nastavení WireGuard Serveru (pokud je dodán Private Key)
if [ -n "$WG_PRIVATE_KEY" ]; then
    echo "Konfiguruji WireGuard server..."
    cat <<EOF > /etc/wireguard/wg0.conf
[Interface]
Address = 10.0.0.1/24
ListenPort = 51820
PrivateKey = $WG_PRIVATE_KEY
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o tun0 -j MASQUERADE
EOF
    # Přidání peerů (klientů) z proměnné
    if [ -n "$WG_PEERS" ]; then
        echo "$WG_PEERS" >> /etc/wireguard/wg0.conf
    fi
    wg-quick up wg0
fi

# 3. Spuštění CyberGhost
PROTOCOL=${CG_PROTOCOL:-openvpn}
COUNTRY=${CG_COUNTRY:-US}
cyberghostvpn --setup --username "$CG_USERNAME" --password "$CG_PASSWORD"
cyberghostvpn --$PROTOCOL --country-code "$COUNTRY" --connect

# 4. Start Proxy
tinyproxy -c /etc/tinyproxy/tinyproxy.conf

echo "Vše běží! VPN, Proxy i WireGuard Server."
trap "wg-quick down wg0; cyberghostvpn --stop; exit" SIGTERM SIGINT
tail -f /var/log/tinyproxy/tinyproxy.log & wait
