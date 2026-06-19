#!/usr/bin/env bash
set -euo pipefail

export DISPLAY="${DISPLAY:-:0}"
export HOME="${HOME:-/root}"
export WINEPREFIX="${WINEPREFIX:-$HOME/.steam-wine}"
TERMUX_HOME="${TERMUX_HOME:-/data/data/com.termux/files/home}"
LOG_DIR="${LOG_DIR:-$TERMUX_HOME/.termux-steam-headless/logs}"
mkdir -p "$LOG_DIR"

log() {
    printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*" | tee -a "$LOG_DIR/start.log"
}

wait_for_display() {
    local i max=60
    log "Esperando display $DISPLAY (abre Termux:X11 si tarda)..."
    for i in $(seq 1 "$max"); do
        if xdpyinfo -display "$DISPLAY" >/dev/null 2>&1; then
            log "Display listo (${i}s)"
            return 0
        fi
        sleep 1
    done
    log "Display $DISPLAY no disponible tras ${max}s. Abre Termux:X11-Extra y ejecuta: steam-headless start"
    return 1
}

start_dbus() {
    if pgrep -x dbus-daemon >/dev/null 2>&1; then
        return
    fi
    eval "$(dbus-launch --sh-syntax)"
    export DBUS_SESSION_BUS_ADDRESS
    log "D-Bus iniciado"
}

start_pulse() {
    if pulseaudio --check 2>/dev/null; then
        return
    fi
    pulseaudio --start --exit-idle-time=-1 --log-target=file:"$LOG_DIR/pulse.log" 2>/dev/null || \
        pulseaudio --start --exit-idle-time=-1 || true
    log "PulseAudio iniciado"
}

start_desktop() {
    if pgrep -f xfce4-session >/dev/null 2>&1; then
        log "XFCE ya en ejecución"
        return
    fi
    nohup dbus-launch --exit-with-session startxfce4 >"$LOG_DIR/xfce.log" 2>&1 &
    sleep 5
    log "XFCE iniciado"
}

start_vnc() {
    if pgrep -x x11vnc >/dev/null 2>&1; then
        log "x11vnc ya en ejecución"
        return
    fi

    local pass_file="$HOME/.vnc/passwd"
    if [[ ! -f "$pass_file" ]]; then
        x11vnc -storepasswd steamheadless "$pass_file"
    fi

    nohup x11vnc \
        -display "$DISPLAY" \
        -forever \
        -shared \
        -rfbauth "$pass_file" \
        -rfbport 5900 \
        -noxdamage \
        >"$LOG_DIR/x11vnc.log" 2>&1 &

    sleep 2
    log "x11vnc en puerto 5900"
}

start_novnc() {
    if pgrep -f "websockify.*6080" >/dev/null 2>&1; then
        log "noVNC ya en ejecución"
        return
    fi

    local web_root="/usr/share/novnc"
    [[ -d "$web_root" ]] || web_root="/usr/share/novnc/utils"

    nohup websockify --web="$web_root" 0.0.0.0:6080 localhost:5900 \
        >"$LOG_DIR/novnc.log" 2>&1 &

    sleep 1
    log "noVNC en http://0.0.0.0:6080/vnc.html"
}

main() {
    log "=== Iniciando termux-steam-headless ==="
    wait_for_display
    start_dbus
    start_pulse
    start_desktop
    start_vnc
    start_novnc
    log "=== Listo ==="
    tail -f "$LOG_DIR/x11vnc.log" "$LOG_DIR/novnc.log" 2>/dev/null &
    wait
}

main "$@"
