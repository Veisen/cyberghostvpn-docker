#!/bin/bash
set -e

# --- 1. KONTROLA PROMĚNNÝCH ---
if [ -z "$CG_USERNAME" ] || [ -z "$CG_PASSWORD" ]; then
    echo "CHYBA: Musíte nastavit proměnné CG_USERNAME a CG_PASSWORD!"
    exit 1
fi

# Výchozí hodnoty, pokud nejsou zadány
PROTOCOL=${CG_PROTOCOL:-openvpn}
COUNTRY=${CG_COUNTRY:-CZ}
CITY=${CG_CITY} # Volitelné

# --- 2. NASTAVENÍ CYBERGHOST ---
echo "Konfiguruji CyberGhost účet..."
cyberghostvpn --setup --username "$CG_USERNAME" --password "$CG_PASSWORD"

# --- 3. VOLITELNÉ: DRÁTOVÁ STRÁŽ (WIREGUARD SERVER) ---
# Pokud jsi předal privátní klíč, nastavíme WG server pro tvůj mobil/PC
if [ -n "$WG_PRIVATE_KEY" ]; then
    echo "Nastavuji WireGuard server (wg0)..."
    mkdir -p /etc/wireguard
    cat <<EOF > /etc/wireguard/wg0.conf
[Interface]
Address = 10.0.0.1/24
ListenPort = 51820
PrivateKey = $WG_PRIVATE_KEY
# Pravidla pro průchod provozu z WireGuardu do VPN tunelu
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o tun0 -j MASQUERADE
EOF

    # Přidání peerů (klientů), pokud jsou definováni
    if [ -n "$WG_PEERS" ]; then
        echo "$WG_PEERS" >> /etc/wireguard/wg0.conf
    fi

    # Spuštění WG rozhraní
    wg-quick up wg0 || echo "Varování: Nepodařilo se spustit wg0. Ujistěte se, že má kontejner --privileged."
fi

# --- 4. PŘIPOJENÍ K VPN ---
echo "Připojuji k CyberGhost VPN (Země: $COUNTRY, Protokol: $PROTOCOL)..."

# Sestavení příkazu pro připojení
CONN_CMD="cyberghostvpn --$PROTOCOL --country-code $COUNTRY"
if [ -n "$CITY" ]; then
    CONN_CMD="$CONN_CMD --city $CITY"
fi
CONN_CMD="$CONN_CMD --connect"

# Spuštění připojení
$CONN_CMD

# --- 5. START PROXY SERVERU ---
echo "Spouštím Tinyproxy na portu 8888..."
# Tinyproxy zapisuje logy do /var/log/tinyproxy/tinyproxy.log
touch /var/log/tinyproxy/tinyproxy.log
tinyproxy -c /etc/tinyproxy/tinyproxy.conf

# --- 6. ÚDRŽBA A LOGOVÁNÍ ---
echo "Všechny služby jsou spuštěny."

# Funkce pro korektní ukončení při zastavení kontejneru
cleanup() {
    echo "Zastavuji VPN a Proxy..."
    cyberghostvpn --stop
    pkill tinyproxy
    if [ -n "$WG_PRIVATE_KEY" ]; then wg-quick down wg0; fi
    exit 0
}

trap cleanup SIGTERM SIGINT

# Sledujeme logy proxy, aby kontejner neběžel "naprázdno" a neukončil se
tail -f /var/log/tinyproxy/tinyproxy.log & wait
