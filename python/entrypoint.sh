#!/bin/bash
cd /home/container || exit 1

export INTERNAL_IP="$(ip route get 1 2>/dev/null | awk '{print $(NF-2);exit}')"

printf '\033[1m\033[33mcontainer@bimxyz~ \033[0mpython -V\n'
python -V

# Kompatibilitas server lama: startup command tersimpan per-server di panel dan tidak ikut ter-update
# saat egg di-update. Startup lama (pakai PY_FILE) dialihkan ke start.sh baru.
case "${STARTUP}" in
    *PY_FILE*)
        echo "[Bimxyz] Startup lama (PY_FILE) terdeteksi, memakai /usr/local/bin/start.sh."
        echo "[Bimxyz] Admin: reset Startup Command server ini ke /usr/local/bin/start.sh."
        STARTUP="/usr/local/bin/start.sh"
        ;;
esac

MODIFIED_STARTUP="$(echo -e ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')"
printf ':/home/container$ %s\n' "${MODIFIED_STARTUP}"

eval ${MODIFIED_STARTUP}
