#!/usr/bin/env bash
set -euo pipefail

check() {
    local name="$1" pattern="$2"
    if pgrep -f "$pattern" >/dev/null 2>&1; then
        printf '  [OK] %s\n' "$name"
    else
        printf '  [--] %s\n' "$name"
    fi
}

export DISPLAY="${DISPLAY:-:0}"

echo "termux-steam-headless — estado"
echo "Display: $DISPLAY"
xdpyinfo -display "$DISPLAY" >/dev/null 2>&1 && echo "  [OK] X11 display" || echo "  [--] X11 display (abre Termux:X11)"

check "D-Bus" dbus-daemon
check "PulseAudio" pulseaudio
check "XFCE" xfce4-session
check "x11vnc :5900" x11vnc
check "noVNC :6080" "websockify.*6080"
