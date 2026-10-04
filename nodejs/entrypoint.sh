#!/bin/bash
cd /home/container || exit 1

export INTERNAL_IP="$(ip route get 1 2>/dev/null | awk '{print $(NF-2);exit}')"

printf '\033[1m\033[33mcontainer@bimxyz~ \033[0mnode -v\n'
node -v

MODIFIED_STARTUP="$(echo -e ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')"
printf ':/home/container$ %s\n' "${MODIFIED_STARTUP}"

eval ${MODIFIED_STARTUP}
