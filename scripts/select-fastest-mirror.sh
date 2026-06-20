#!/data/data/com.termux/files/usr/bin/bash
# Selecciona el mirror de Termux con menor latencia (sin interacción).

termux_mirror_log() {
    printf '\033[1;36m[mirror] %s\033[0m\n' "$*"
}

termux_mirror_probe() {
    local main_url="$1"
    local probe="${main_url%/}/dists/stable/InRelease"
    curl -fsSL -o /dev/null \
        -w '%{time_total}' \
        --connect-timeout 4 \
        --max-time 12 \
        "$probe" 2>/dev/null || echo "99"
}

termux_mirror_apply_file() {
    local mirror_file="$1"
    local chosen="${PREFIX}/etc/termux/chosen_mirrors"

    rm -f "$chosen" "${chosen}.dpkg-old" "${chosen}.dpkg-new" 2>/dev/null || true
    ln -sfn "$mirror_file" "$chosen"

    rm -f "${PREFIX}/var/cache/apt/pkgcache.bin" 2>/dev/null || true
    rm -f "${TERMUX_CACHE_DIR:-$PREFIX/var/cache/apt}/pkgcache.bin" 2>/dev/null || true
}

termux_mirror_apply_urls() {
    local main="$1" root="$2" x11="$3"
    local tmp="${PREFIX}/etc/termux/mirrors/termux-steam-headless-fastest"

    mkdir -p "$(dirname "$tmp")"
    cat >"$tmp" <<EOF
# This file is sourced by pkg
# Mirror auto-selected by termux-steam-headless (lowest latency)
WEIGHT=999
MAIN="$main"
ROOT="$root"
X11="$x11"
EOF
    termux_mirror_apply_file "$tmp"
}

termux_mirror_collect_files() {
    local mirror_base="${PREFIX}/etc/termux/mirrors"
    local -a files=()

    if [[ ! -d "$mirror_base" ]]; then
        return 0
    fi

    while IFS= read -r -d '' f; do
        [[ -f "$f" ]] || continue
        [[ "$f" == *".dpkg-"* ]] && continue
        files+=("$f")
    done < <(find "$mirror_base" -type f ! -name '*~' -print0 2>/dev/null)

    printf '%s\n' "${files[@]}"
}

termux_mirror_benchmark_files() {
    local -a files=("$@")
    local tmp result best_time=99 best_file="" f main_url t desc

    if [[ ${#files[@]} -eq 0 ]]; then
        return 1
    fi

    tmp="$(mktemp -d "${TMPDIR:-/tmp}/tsh-mirror.XXXXXX")"
    termux_mirror_log "Probando ${#files[@]} mirrors de Termux..."

    for f in "${files[@]}"; do
        (
            # shellcheck disable=SC1090
            source "$f"
            [[ -n "${MAIN:-}" ]] || exit 0
            t="$(termux_mirror_probe "$MAIN")"
            printf '%s %s\n' "$t" "$f"
        ) >"$tmp/$(basename "$f").result" 2>/dev/null &
    done
    wait

    for f in "$tmp"/*.result; do
        [[ -f "$f" ]] || continue
        read -r t mirror_path <"$f" || continue
        if awk -v t="$t" -v b="$best_time" 'BEGIN { exit !(t+0 < b+0) }'; then
            best_time="$t"
            best_file="$mirror_path"
        fi
    done

    rm -rf "$tmp"

    if [[ -z "$best_file" ]]; then
        return 1
    fi

    # shellcheck disable=SC1090
    source "$best_file"
    desc="$(grep -m1 '^# Mirror' "$best_file" 2>/dev/null | sed 's/^# //' || basename "$best_file")"
    termux_mirror_log "Mirror elegido (${best_time}s): ${desc:-$MAIN}"
    termux_mirror_apply_file "$best_file"
}

termux_mirror_benchmark_fallbacks() {
    local -a fallbacks=(
        "https://packages-cf.termux.dev/apt/termux-main|https://packages-cf.termux.dev/apt/termux-root|https://packages-cf.termux.dev/apt/termux-x11|Cloudflare CDN"
        "https://packages.termux.dev/apt/termux-main|https://packages.termux.dev/apt/termux-root|https://packages.termux.dev/apt/termux-x11|Primary"
        "https://mirror.freedif.org/termux/termux-main|https://mirror.freedif.org/termux/termux-root|https://mirror.freedif.org/termux/termux-x11|Singapore"
        "https://grimler.se/termux/termux-main|https://grimler.se/termux/termux-root|https://grimler.se/termux/termux-x11|Sweden"
        "https://ftp.fau.de/termux/termux-main|https://ftp.fau.de/termux/termux-root|https://ftp.fau.de/termux/termux-x11|Germany"
        "https://mirror.meowsmp.net/termux/termux-main|https://mirror.meowsmp.net/termux/termux-root|https://mirror.meowsmp.net/termux/termux-x11|Vietnam"
    )

    local entry main root x11 label best_time=99 best_main="" best_root="" best_x11="" best_label="" t

    termux_mirror_log "Usando lista de mirrors de respaldo..."

    for entry in "${fallbacks[@]}"; do
        IFS='|' read -r main root x11 label <<<"$entry"
        t="$(termux_mirror_probe "$main")"
        if awk -v t="$t" -v b="$best_time" 'BEGIN { exit !(t+0 < b+0) }'; then
            best_time="$t"
            best_main="$main"
            best_root="$root"
            best_x11="$x11"
            best_label="$label"
        fi
    done

    [[ -n "$best_main" ]] || return 1
    termux_mirror_log "Mirror elegido (${best_time}s): ${best_label}"
    termux_mirror_apply_urls "$best_main" "$best_root" "$best_x11"
}

# Punto de entrada: elegir mirror más rápido antes de pkg update/install
termux_select_fastest_mirror() {
    command -v curl >/dev/null 2>&1 || {
        termux_mirror_log "curl no disponible; se usa mirror por defecto de pkg"
        return 0
    }

    mkdir -p "${PREFIX}/etc/termux/mirrors"

    local -a files=()
    while IFS= read -r f; do
        [[ -n "$f" ]] && files+=("$f")
    done < <(termux_mirror_collect_files)

    if [[ ${#files[@]} -gt 0 ]]; then
        termux_mirror_benchmark_files "${files[@]}" && return 0
        termux_mirror_log "Benchmark de mirrors locales falló; probando respaldo..."
    else
        termux_mirror_log "No hay mirrors en ${PREFIX}/etc/termux/mirrors; probando respaldo..."
    fi

    termux_mirror_benchmark_fallbacks || termux_mirror_log "No se pudo fijar mirror; pkg usará el suyo"
}
