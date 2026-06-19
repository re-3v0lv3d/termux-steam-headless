#!/usr/bin/env bash
set -euo pipefail

kill_if_running() {
    local pattern="$1"
    pkill -f "$pattern" 2>/dev/null || true
}

kill_if_running "websockify.*6080"
kill_if_running x11vnc
kill_if_running xfce4-session
kill_if_running xfconfd
kill_if_running xfwm4
kill_if_running Thunar

pulseaudio --kill 2>/dev/null || true
pkill -x dbus-daemon 2>/dev/null || true

echo "Servicios internos detenidos."
