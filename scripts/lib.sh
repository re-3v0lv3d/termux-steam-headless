#!/data/data/com.termux/files/usr/bin/bash
# Utilidades compartidas: /dev/shm y proot-distro (v4 legacy + v5 OCI)

TSH_SHM_DIR="${TSH_SHM_DIR:-$HOME/.termux-steam-headless/shm}"
TSH_STATE_DIR="${TSH_STATE_DIR:-$HOME/.termux-steam-headless}"

proot_get_name() {
    if [[ -f "$TSH_STATE_DIR/proot-name" ]]; then
        cat "$TSH_STATE_DIR/proot-name"
    else
        echo "${PROOT_NAME:-ubuntu}"
    fi
}

proot_get_image() {
    if [[ -f "$TSH_STATE_DIR/proot-image" ]]; then
        cat "$TSH_STATE_DIR/proot-image"
    else
        echo "${PROOT_IMAGE:-ubuntu:24.04}"
    fi
}

proot_save_config() {
    local name="${1:-ubuntu}"
    local image="${2:-ubuntu:24.04}"
    mkdir -p "$TSH_STATE_DIR"
    echo "$name" >"$TSH_STATE_DIR/proot-name"
    echo "$image" >"$TSH_STATE_DIR/proot-image"
}

proot_distro_is_v5() {
    proot-distro install --help 2>&1 | grep -q 'IMAGE or PATH'
}

proot_container_installed() {
    local name="${1:-$(proot_get_name)}"
    proot-distro list -q 2>/dev/null | grep -qx "$name"
}

setup_shm_host() {
    mkdir -p "$TSH_SHM_DIR"
    chmod 1777 "$TSH_SHM_DIR" 2>/dev/null || chmod 755 "$TSH_SHM_DIR"

    if [[ -d /dev/shm ]] && [[ -w /dev/shm ]]; then
        export TSH_SHM_BIND=""
    else
        export TSH_SHM_BIND="$TSH_SHM_DIR"
    fi
}

# Uso: proot_login -- bash script.sh   (nombre de contenedor desde config)
#      proot_login ubuntu -- bash ...  (nombre explícito)
proot_login() {
    local distro
    if [[ "${1:-}" == "--" ]]; then
        distro="$(proot_get_name)"
    else
        distro="${1:-$(proot_get_name)}"
        shift || true
    fi

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

proot_install_container() {
    local name image
    name="${PROOT_NAME:-$(proot_get_name)}"
    image="${PROOT_IMAGE:-$(proot_get_image)}"
    proot_save_config "$name" "$image"

    if proot_container_installed "$name"; then
        return 0
    fi

    if proot_distro_is_v5; then
        proot-distro install "$image" --name "$name" </dev/null
    else
        proot-distro install "$name" </dev/null
    fi
}
