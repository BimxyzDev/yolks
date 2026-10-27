#!/bin/bash
cd /home/container || exit 1

CF_LOG=/home/container/cloudflared.log
CF_PID=""

cleanup() {
    [ -n "${CF_PID}" ] && kill "${CF_PID}" 2>/dev/null
}
trap cleanup EXIT
trap 'exit 0' INT TERM

# ---------------------------------------------------------------- git auto update
if [ -d .git ] && [ "${AUTO_UPDATE}" == "1" ]; then
    git pull
fi

# ---------------------------------------------------------------- Cloudflare Tunnel
if [ "${ENABLE_CLOUDFLARE_TUNNEL}" == "1" ]; then
    CF_BIN="$(command -v cloudflared)"
    if [ -z "${CF_BIN}" ] && [ -x /home/container/cloudflared ]; then
        CF_BIN=/home/container/cloudflared
    fi
    if [ -z "${CF_BIN}" ]; then
        echo "ERROR: cloudflared tidak ditemukan. Pakai Docker Image bimxyzdev (Python + Cloudflared)."
        exit 1
    fi

    : > "${CF_LOG}"

    if [ -n "${CF_TUNNEL_TOKEN}" ]; then
        echo "Cloudflare Tunnel: Named Tunnel"
    else
        echo "Cloudflare Tunnel: Quick Tunnel"
        echo "Target: http://127.0.0.1:${SERVER_PORT}"
        echo "Quick Tunnel URL will appear in ${CF_LOG}"
    fi

    (
        CFC=""
        trap '[ -n "${CFC}" ] && kill "${CFC}" 2>/dev/null; exit 0' INT TERM
        while true; do
            if [ -n "${CF_TUNNEL_TOKEN}" ]; then
                "${CF_BIN}" tunnel --no-autoupdate run --token "${CF_TUNNEL_TOKEN}" >> "${CF_LOG}" 2>&1 &
            else
                "${CF_BIN}" tunnel --no-autoupdate --url "http://127.0.0.1:${SERVER_PORT}" >> "${CF_LOG}" 2>&1 &
            fi
            CFC=$!
            wait "${CFC}"
            echo "cloudflared exited; retrying in 5s." >> "${CF_LOG}"
            tail -n 500 "${CF_LOG}" > "${CF_LOG}.tmp" && mv "${CF_LOG}.tmp" "${CF_LOG}"
            sleep 5 &
            wait $!
        done
    ) &
    CF_PID=$!

    # tampilkan URL Quick Tunnel di console begitu tersedia
    if [ -z "${CF_TUNNEL_TOKEN}" ]; then
        (
            for _ in $(seq 1 60); do
                URL="$(grep -Eo 'https://[A-Za-z0-9.-]+\.trycloudflare\.com' "${CF_LOG}" 2>/dev/null | tail -n 1)"
                if [ -n "${URL}" ]; then
                    echo "[Bimxyz] Cloudflare Quick Tunnel: ${URL}"
                    break
                fi
                sleep 2
            done
        ) &
    fi
fi

# ---------------------------------------------------------------- pip packages
PKG_RE='^[A-Za-z0-9][A-Za-z0-9._,<>=!~^*+@:/\[\]-]*$'

parse_pkgs() {
    PKGS=()
    case "$1" in
        *$'\n'*|*$'\r'*) return 1 ;;
    esac
    read -r -a PKGS <<< "$1"
    local p
    for p in "${PKGS[@]}"; do
        [[ "${p}" =~ ${PKG_RE} ]] || return 1
    done
    return 0
}

REQ_FILE="${REQUIREMENTS_FILE:-requirements.txt}"
if [ -f "/home/container/${REQ_FILE}" ]; then
    pip install -U --user -r "/home/container/${REQ_FILE}"
fi

if [ -n "${PY_PACKAGES}" ]; then
    if parse_pkgs "${PY_PACKAGES}"; then
        pip install -U --user -- "${PKGS[@]}"
    else
        echo "ERROR: Additional Python Packages berisi karakter/opsi tidak valid, dilewati."
    fi
fi
if [ -n "${UNPY_PACKAGES}" ]; then
    if parse_pkgs "${UNPY_PACKAGES}"; then
        pip uninstall -y -- "${PKGS[@]}"
    else
        echo "ERROR: Remove Python Packages berisi karakter/opsi tidak valid, dilewati."
    fi
fi

printf '\n\033[32m===================================================\033[0m\n  \033[33mCari panel hosting murah berkualitas di bimxyz.id\033[0m  \n\033[32m===================================================\033[0m\n\n'

# ---------------------------------------------------------------- app
if [ -n "${CMD_RUN}" ]; then
    eval "${CMD_RUN}"
fi

# ---------------------------------------------------------------- shell console
if [ "${ENABLE_SHELL}" == "1" ]; then
    show_prompt() {
        printf '\033[1;32mBimxyz\033[0m#:\n'
    }
    echo "[shell] Shell mode aktif, server running. Ketik perintah bash di console, ketik exit untuk stop."
    show_prompt
    while IFS= read -r SHELL_LINE; do
        if [ -z "${SHELL_LINE}" ]; then
            show_prompt
            continue
        fi
        printf '\033[1;32mBimxyz\033[0m#: %s\n' "${SHELL_LINE}"
        eval "${SHELL_LINE}"
        SHELL_RC=$?
        if [ ${SHELL_RC} -ne 0 ]; then
            echo "[exit ${SHELL_RC}]"
        fi
        show_prompt
    done
fi
