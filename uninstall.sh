#!/data/data/com.termux/files/usr/bin/bash
# Desinstala termux-steam-headless
set -euo pipefail

log() { printf '[+] %s\n' "$*"; }

steam-headless stop 2>/dev/null || true

rm -f "$PREFIX/bin/steam-headless"
rm -f "$HOME/.termux-steam-headless-installed"
rm -rf "$HOME/.termux-steam-headless"

read -r -p "¿Eliminar también ~/termux-steam-headless y Ubuntu proot? [s/N] " ans
case "$ans" in
    s|S|y|Y)
        rm -rf "$HOME/termux-steam-headless"
        proot-distro reset ubuntu 2>/dev/null || proot-distro uninstall ubuntu 2>/dev/null || true
        log "Eliminado completamente."
        ;;
    *)
        log "Configuración y launcher eliminados. Repo y proot conservados."
        ;;
esac
