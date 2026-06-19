#!/data/data/com.termux/files/usr/bin/bash
# Gestión de /dev/shm en Termux (Android no permite crear /dev/shm sin root)

TSH_SHM_DIR="${TSH_SHM_DIR:-$HOME/.termux-steam-headless/shm}"

setup_shm_host() {
    mkdir -p "$TSH_SHM_DIR"
    chmod 1777 "$TSH_SHM_DIR" 2>/dev/null || chmod 755 "$TSH_SHM_DIR"

    # En Termux normal /dev/shm no existe o no es escribible
    if [[ -d /dev/shm ]] && [[ -w /dev/shm ]]; then
        export TSH_SHM_BIND=""
    else
        export TSH_SHM_BIND="$TSH_SHM_DIR"
    fi
}

# Uso: proot_login ubuntu -- bash script.sh
#      proot_login ubuntu            # shell interactivo
proot_login() {
    local distro="${1:-ubuntu}"
    shift || true

    setup_shm_host

    local args=(login "$distro" --shared-tmp)
    if [[ -n "${TSH_SHM_BIND:-}" ]]; then
        args+=(--bind "${TSH_SHM_BIND}:/dev/shm")
    fi

    if [[ $# -gt 0 ]]; then
        args+=(-- "$@")
    fi

    proot-distro "${args[@]}"
}
