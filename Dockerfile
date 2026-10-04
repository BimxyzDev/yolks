ARG NODE_VERSION=22
FROM node:${NODE_VERSION}-bookworm-slim

ARG TARGETARCH
ARG CLOUDFLARED_VERSION=latest

LABEL org.opencontainers.image.source="https://github.com/BimxyzDev/yolks"

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl git jq ffmpeg iproute2 dnsutils iputils-ping \
      sqlite3 libsqlite3-dev python3 python3-dev build-essential libtool \
      tzdata zip unzip tar tini fonts-liberation chromium \
 && if [ "${CLOUDFLARED_VERSION}" = "latest" ]; then \
      CF_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${TARGETARCH}"; \
    else \
      CF_URL="https://github.com/cloudflare/cloudflared/releases/download/${CLOUDFLARED_VERSION}/cloudflared-linux-${TARGETARCH}"; \
    fi \
 && curl --fail --location --silent --show-error "${CF_URL}" -o /usr/local/bin/cloudflared \
 && chmod 755 /usr/local/bin/cloudflared \
 && cloudflared --version \
 && useradd -m -d /home/container -s /bin/bash container \
 && rm -rf /var/lib/apt/lists/*

USER container
ENV USER=container \
    HOME=/home/container \
    PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

WORKDIR /home/container

COPY --chmod=755 entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/usr/bin/tini", "-g", "--"]
CMD ["/bin/bash", "/entrypoint.sh"]
