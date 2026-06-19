#!/usr/bin/env bash
# Instala Box64 y Box86 precompilados para ARM64 Linux (dentro del proot)
set -euo pipefail

ARCH="$(uname -m)"
BOX_DIR="/usr/local/bin"

log() { printf '[install-box] %s\n' "$*"; }

if [[ "$ARCH" != "aarch64" && "$ARCH" != "arm64" ]]; then
    log "Arquitectura $ARCH: omitiendo Box64/Box86 (solo aarch64 soportado en este script)."
    exit 0
fi

install_box64() {
    if command -v box64 >/dev/null 2>&1; then
        log "box64 ya instalado: $(box64 -v 2>/dev/null | head -1 || true)"
        return
    fi

    local tag asset
    if command -v jq >/dev/null 2>&1; then
        tag="$(curl -fsSL https://api.github.com/repos/ptitSeb/box64/releases/latest | jq -r '.tag_name')"
        asset="$(curl -fsSL "https://api.github.com/repos/ptitSeb/box64/releases/tags/${tag}" \
            | jq -r '.assets[] | select(.name | test("Generic.*ARM64|generic.*arm64|aarch64")) | .browser_download_url' | head -1)"
    else
        tag="$(curl -fsSL https://api.github.com/repos/ptitSeb/box64/releases/latest | grep -o '"tag_name": *"[^"]*"' | head -1 | cut -d'"' -f4)"
        asset=""
    fi

    if [[ -z "$asset" || "$asset" == "null" ]]; then
        log "No se encontró binario Box64 ARM64 en release ${tag:-unknown}; compilación manual requerida."
        return
    fi

    log "Descargando Box64 ${tag}..."
    tmp="$(mktemp -d)"
    wget -O "$tmp/box64.tgz" "$asset"
    tar -xzf "$tmp/box64.tgz" -C "$tmp"
    find "$tmp" -name box64 -type f -executable | head -1 | xargs -I{} cp {} "$BOX_DIR/box64"
    chmod +x "$BOX_DIR/box64"
    rm -rf "$tmp"
    log "Box64 instalado en $BOX_DIR/box64"
}

install_box86() {
    if command -v box86 >/dev/null 2>&1; then
        log "box86 ya instalado: $(box86 -v 2>/dev/null | head -1 || true)"
        return
    fi

    local tag asset
    tag="$(curl -fsSL https://api.github.com/repos/ptitSeb/box86/releases/latest | jq -r '.tag_name')"
    asset="$(curl -fsSL "https://api.github.com/repos/ptitSeb/box86/releases/tags/${tag}" \
        | jq -r '.assets[] | select(.name | test("Generic.*ARM|generic.*arm|armhf")) | .browser_download_url' | head -1)"

    if [[ -z "$asset" || "$asset" == "null" ]]; then
        log "No se encontró binario Box86 ARM en release ${tag}."
        return
    fi

    log "Descargando Box86 ${tag}..."
    tmp="$(mktemp -d)"
    wget -O "$tmp/box86.tgz" "$asset"
    tar -xzf "$tmp/box86.tgz" -C "$tmp"
    find "$tmp" -name box86 -type f -executable | head -1 | xargs -I{} cp {} "$BOX_DIR/box86"
    chmod +x "$BOX_DIR/box86"
    rm -rf "$tmp"
    log "Box86 instalado en $BOX_DIR/box86"
}

install_box64
install_box86
