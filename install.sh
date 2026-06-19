#!/data/data/com.termux/files/usr/bin/bash
# termux-steam-headless — instalador one-liner
#
# Usuario final (copiar y pegar en Termux):
#   curl -fsSL https://raw.githubusercontent.com/re-3v0lv3d/termux-steam-headless/main/install.sh | bash
#
# Mantenedor: cambia TSH_REPO_DEFAULT abajo por tu usuario/repo de GitHub.
set -euo pipefail

# ── Configuración del repositorio (edita al publicar en GitHub) ──────────────
TSH_REPO_DEFAULT="${TSH_REPO_DEFAULT:-re-3v0lv3d/termux-steam-headless}"
TSH_BRANCH="${TSH_BRANCH:-main}"
TSH_INSTALL_DIR="${TSH_INSTALL_DIR:-$HOME/termux-steam-headless}"

TSH_REPO="${TSH_REPO:-$TSH_REPO_DEFAULT}"
REPO_URL="https://github.com/${TSH_REPO}.git"
RAW_BASE="https://raw.githubusercontent.com/${TSH_REPO}/${TSH_BRANCH}"

STATE_FILE="$HOME/.termux-steam-headless-installed"
PROOT_DISTRO="${PROOT_DISTRO:-ubuntu}"
AUTO_START="${AUTO_START:-1}"

log()  { printf '\033[1;32m[+] %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m[!] %s\033[0m\n' "$*"; }
err()  { printf '\033[1;31m[x] %s\033[0m\n' "$*" >&2; }
die()  { err "$*"; exit 1; }

# ── Bootstrap: clonar repo si se ejecuta vía curl | bash ─────────────────────
bootstrap_repo() {
    local script_path=""
    script_path="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || realpath "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"

    if [[ -f "${script_path%/*}/scripts/proot-setup.sh" ]]; then
        ROOT_DIR="$(cd "${script_path%/*}" && pwd)"
        return 0
    fi

    if [[ "$TSH_REPO" == *"TU_USUARIO"* ]]; then
        die "Configura tu repositorio: export TSH_REPO=usuario/termux-steam-headless"
    fi

    log "Descargando repositorio ${TSH_REPO}..."
    pkg install -y git curl >/dev/null 2>&1 || pkg install -y git curl

    if [[ -d "$TSH_INSTALL_DIR/.git" ]]; then
        log "Actualizando instalación existente..."
        git -C "$TSH_INSTALL_DIR" fetch origin "$TSH_BRANCH"
        git -C "$TSH_INSTALL_DIR" reset --hard "origin/${TSH_BRANCH}"
    else
        rm -rf "$TSH_INSTALL_DIR"
        git clone --depth 1 --branch "$TSH_BRANCH" "$REPO_URL" "$TSH_INSTALL_DIR"
    fi

    ROOT_DIR="$TSH_INSTALL_DIR"
    exec bash "$TSH_INSTALL_DIR/install.sh" --local "$@"
}

parse_args() {
    LOCAL_RUN=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --local)    LOCAL_RUN=1; shift ;;
            --no-start) AUTO_START=0; shift ;;
            -h|--help)
                cat <<'EOF'
termux-steam-headless install.sh

Uso:
  curl -fsSL .../install.sh | bash          Instalación completa automática
  bash install.sh --no-start                Instalar sin arrancar servicios

Variables:
  TSH_REPO=usuario/repo     Repositorio GitHub
  TSH_BRANCH=main           Rama a clonar
  AUTO_START=0              No iniciar al terminar
EOF
                exit 0
                ;;
            *) shift ;;
        esac
    done
}

require_termux() {
    [[ -n "${PREFIX:-}" && -d "$PREFIX" ]] || die "Ejecuta esto solo dentro de Termux (instálalo desde F-Droid)."
}

install_termux_packages() {
    log "Actualizando paquetes de Termux..."
    yes | pkg update
    yes | pkg upgrade || true

    log "Instalando dependencias..."
    pkg install -y \
        proot-distro wget curl git tar unzip \
        pulseaudio dbus x11-repo jq

    if pkg list-installed 2>/dev/null | grep -q '^termux-x11 '; then
        log "termux-x11 ya instalado"
    else
        log "Instalando termux-x11..."
        pkg install -y termux-x11 || warn "Instala Termux:X11-Extra manualmente para mandos BT."
    fi
}

install_proot_distro() {
    if proot-distro list 2>/dev/null | awk 'NR>1 {print $1}' | grep -qx "$PROOT_DISTRO"; then
        log "Distro proot '$PROOT_DISTRO' ya instalada"
        return
    fi
    log "Instalando Ubuntu via proot-distro (varios minutos)..."
    proot-distro install "$PROOT_DISTRO"
}

install_launcher() {
    mkdir -p "$PREFIX/bin" "$HOME/.termux-steam-headless"
    ln -sf "$ROOT_DIR/bin/steam-headless" "$PREFIX/bin/steam-headless"
    chmod +x "$ROOT_DIR/bin/steam-headless" "$ROOT_DIR/scripts/"*.sh
    echo "$ROOT_DIR" >"$HOME/.termux-steam-headless/root-dir"
    log "Comando instalado: steam-headless"
}

run_proot_setup() {
    if [[ -f "$STATE_FILE" ]]; then
        log "Entorno proot ya configurado. Saltando setup interno."
        return
    fi

    log "Configurando Ubuntu proot (15-40 min la primera vez)..."
    setup_shm_host
    if [[ -n "${TSH_SHM_BIND:-}" ]]; then
        log "Usando bind mount: ${TSH_SHM_BIND} → /dev/shm"
    fi
    proot_login "$PROOT_DISTRO" -- bash "$ROOT_DIR/scripts/proot-setup.sh" "$ROOT_DIR"
    touch "$STATE_FILE"
}

launch_x11_app() {
    if command -v am >/dev/null 2>&1; then
        am start -n com.termux.x11.extra/.MainActivity >/dev/null 2>&1 \
            || am start -n com.termux.x11/.MainActivity >/dev/null 2>&1 \
            || true
    fi
}

auto_start_services() {
    [[ "$AUTO_START" == "1" ]] || { log "AUTO_START=0 — no se inician servicios."; return; }

    log "Abriendo Termux:X11..."
    launch_x11_app
    sleep 3

    log "Iniciando escritorio, VNC y noVNC..."
    steam-headless start

    local ip pass url
    ip="$(bash "$ROOT_DIR/scripts/get-ip.sh")"
    pass="$(cat "$HOME/.termux-steam-headless/vnc-password" 2>/dev/null || echo steamheadless)"
    url="http://${ip}:6080/vnc.html"

    if command -v termux-open-url >/dev/null 2>&1; then
        termux-open-url "$url" 2>/dev/null || true
    fi
}

print_banner() {
    local ip pass
    ip="$(bash "$ROOT_DIR/scripts/get-ip.sh" 2>/dev/null || echo "IP-DEL-MOVIL")"
    pass="$(cat "$HOME/.termux-steam-headless/vnc-password" 2>/dev/null || echo steamheadless)"

    cat <<EOF

╔══════════════════════════════════════════════════════════╗
║         termux-steam-headless — listo                    ║
╚══════════════════════════════════════════════════════════╝

  Navegador:  http://${ip}:6080/vnc.html
  Contraseña: ${pass}

  Comandos:
    steam-headless url
    steam-headless status
    steam-headless stop
    steam-headless logs

  Mandos BT: instala Termux:X11-Extra
    https://github.com/moio9/termux-x11-extra/releases

  Documentación:
    ${RAW_BASE}/README.md

EOF
}

main() {
    parse_args "$@"

    if [[ "${LOCAL_RUN:-0}" != "1" ]]; then
        bootstrap_repo "$@"
    else
        ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    fi

    # shellcheck source=scripts/lib.sh
    source "$ROOT_DIR/scripts/lib.sh"

    require_termux
    setup_shm_host
    install_termux_packages
    install_proot_distro
    install_launcher
    run_proot_setup
    auto_start_services
    print_banner
}

main "$@"
