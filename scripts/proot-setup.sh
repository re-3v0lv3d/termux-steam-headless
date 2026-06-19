#!/usr/bin/env bash
# Ejecutar dentro del proot (Ubuntu)
set -euo pipefail

ROOT_DIR="${1:-}"
FORCE="${2:-}"
MARKER="/root/.termux-steam-headless-proot-done"

[[ -n "$ROOT_DIR" ]] || { echo "ROOT_DIR requerido"; exit 1; }

TERMUX_HOME="${TERMUX_HOME:-/data/data/com.termux/files/home}"
SHARED_STATE="$TERMUX_HOME/.termux-steam-headless"

log()  { printf '[proot-setup] %s\n' "$*"; }
warn() { printf '[proot-setup] WARN: %s\n' "$*"; }

if [[ -f "$MARKER" && "$FORCE" != "--force" ]]; then
    log "Setup proot ya completado. Usa --force para repetir."
    exit 0
fi

export DEBIAN_FRONTEND=noninteractive

log "Actualizando repositorios..."
apt-get update -y </dev/null
apt-get upgrade -y \
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold" </dev/null || true

log "Instalando escritorio, audio, VNC y herramientas..."
apt-get install -y \
    xfce4 xfce4-terminal dbus-x11 \
    pulseaudio pulseaudio-utils \
    x11vnc novnc websockify \
    wget curl ca-certificates gnupg jq \
    software-properties-common \
    winbind cabextract \
    fonts-dejavu fonts-liberation \
    mesa-utils \
    sudo

dpkg --add-architecture i386 || true
apt-get update -y

log "Instalando Wine..."
apt-get install -y --install-recommends wine64 wine32 winetricks || {
    warn "Instalación wine desde apt falló parcialmente; continuando..."
}

bash "$ROOT_DIR/scripts/install-box.sh"

log "Configurando Wine prefix para Steam..."
export WINEPREFIX="${WINEPREFIX:-$HOME/.steam-wine}"
export WINEARCH=win64
export DISPLAY="${DISPLAY:-:0}"

mkdir -p "$WINEPREFIX"
if ! wineboot --init 2>/dev/null; then
    warn "wineboot falló (normal si no hay display activo aún)."
fi

log "Descargando Steam..."
STEAM_DIR="$HOME/.steam-headless"
mkdir -p "$STEAM_DIR"
if [[ ! -f "$STEAM_DIR/SteamSetup.exe" ]]; then
    wget -O "$STEAM_DIR/SteamSetup.exe" \
        "https://cdn.cloudflare.steamstatic.com/client/installer/SteamSetup.exe"
fi

if [[ ! -d "$WINEPREFIX/drive_c/Program Files (x86)/Steam" ]]; then
    log "Instalando Steam en Wine (silencioso)..."
    wine64 "$STEAM_DIR/SteamSetup.exe" /S || warn "Instalador Steam reportó error; puede requerir primer arranque manual."
fi

log "Instalando fuentes Windows para Steam..."
winetricks -q corefonts 2>/dev/null || true

log "Creando scripts de arranque de usuario..."
mkdir -p "$HOME/.config/autostart" "$HOME/.vnc" "$HOME/bin"

cat >"$HOME/bin/steam-bigpicture" <<'STEAM'
#!/usr/bin/env bash
export WINEPREFIX="${WINEPREFIX:-$HOME/.steam-wine}"
export DISPLAY="${DISPLAY:-:0}"
STEAM_EXE="$WINEPREFIX/drive_c/Program Files (x86)/Steam/steam.exe"
if [[ -f "$STEAM_EXE" ]]; then
    wine64 "$STEAM_EXE" -oldbigpicture -bigpicture -windowed
else
    notify-send "Steam no instalado" "Ejecuta steam-headless reinstall" 2>/dev/null || true
fi
STEAM
chmod +x "$HOME/bin/steam-bigpicture"

cat >"$HOME/.config/autostart/steam-bigpicture.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Steam Big Picture
Exec=$HOME/bin/steam-bigpicture
X-GNOME-Autostart-enabled=true
DESKTOP

DEFAULT_PASS="steamheadless"
mkdir -p "$SHARED_STATE"
echo "$DEFAULT_PASS" >"$SHARED_STATE/vnc-password"
x11vnc -storepasswd "$DEFAULT_PASS" "$HOME/.vnc/passwd" 2>/dev/null || true

cp "$ROOT_DIR/scripts/start-services.sh" "$HOME/start-services.sh"
cp "$ROOT_DIR/scripts/stop-services.sh" "$HOME/stop-services.sh"
cp "$ROOT_DIR/scripts/status-services.sh" "$HOME/status-services.sh"
chmod +x "$HOME/"{start,stop,status}-services.sh

touch "$MARKER"
log "Setup proot completado."
