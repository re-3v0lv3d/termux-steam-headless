#!/data/data/com.termux/files/usr/bin/bash
# Obtiene la IP LAN del dispositivo Android en Termux
set -euo pipefail

if command -v termux-wifi-connectioninfo >/dev/null 2>&1; then
    ip="$(termux-wifi-connectioninfo 2>/dev/null | jq -r '.ip // empty' 2>/dev/null || true)"
    [[ -n "$ip" && "$ip" != "null" ]] && { echo "$ip"; exit 0; }
fi

if command -v ip >/dev/null 2>&1; then
    ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1); exit}}' && exit 0
fi

if command -v ifconfig >/dev/null 2>&1; then
    ifconfig wlan0 2>/dev/null | awk '/inet /{print $2; exit}' | sed 's/addr://' && exit 0
fi

echo "127.0.0.1"
