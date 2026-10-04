#!/bin/bash
cd /home/container || exit 1

CF_LOG=/home/container/cloudflared.log

if [ "${ENABLE_CLOUDFLARE_TUNNEL}" == "1" ]; then
    CF_BIN="$(command -v cloudflared)"
    if [ -z "${CF_BIN}" ] && [ -x /home/container/cloudflared ]; then
        CF_BIN=/home/container/cloudflared
    fi
    if [ -z "${CF_BIN}" ]; then
        echo "ERROR: cloudflared tidak ditemukan. Pakai Docker Image bimxyzdev (Chromium + Cloudflared)."
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
        while true; do
            if [ -n "${CF_TUNNEL_TOKEN}" ]; then
                "${CF_BIN}" tunnel --no-autoupdate run --token "${CF_TUNNEL_TOKEN}" >> "${CF_LOG}" 2>&1
            else
                "${CF_BIN}" tunnel --no-autoupdate --url "http://127.0.0.1:${SERVER_PORT}" >> "${CF_LOG}" 2>&1
            fi
            echo "cloudflared exited; retrying in 5s." >> "${CF_LOG}"
            tail -n 500 "${CF_LOG}" > "${CF_LOG}.tmp" && mv "${CF_LOG}.tmp" "${CF_LOG}"
            sleep 5
        done
    ) &
fi

if [ "${ENABLE_CHROMIUM}" == "1" ]; then
    export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
    CHROMIUM_BIN="${PUPPETEER_EXECUTABLE_PATH:-$(command -v chromium || command -v chromium-browser)}"
    if [ -n "${CHROMIUM_BIN}" ]; then
        export PUPPETEER_EXECUTABLE_PATH="${CHROMIUM_BIN}"
    else
        echo "ERROR: Chromium tidak ditemukan. Pakai Docker Image bimxyzdev (Chromium + Cloudflared)."
    fi
fi

if [ -f /home/container/package.json ] && [ /home/container/package.json -nt /home/container/node_modules ]; then
    npm install --omit=dev --no-audit --no-fund
fi
if [ -n "${NODE_PACKAGES}" ]; then
    npm install --no-audit --no-fund ${NODE_PACKAGES}
fi
if [ -n "${UNNODE_PACKAGES}" ]; then
    npm uninstall --no-audit --no-fund ${UNNODE_PACKAGES}
fi

printf '\n\033[32m===================================================\033[0m\n  \033[33mCari panel hosting murah berkualitas di bimxyz.id\033[0m  \n\033[32m===================================================\033[0m\n\n'

if [ -n "${CMD_RUN}" ]; then
    eval "${CMD_RUN}"
fi

if [ "${ENABLE_SHELL}" == "1" ]; then
    show_prompt() {
        printf '\033[1;32mBimxyz\033[0m#:\n'
    }
    trap 'echo "[shell] server stopped."; exit 0' INT TERM
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
