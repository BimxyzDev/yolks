ARG PYTHON_VERSION=3.15
ARG DEBIAN_VARIANT=bookworm
FROM python:${PYTHON_VERSION}-slim-${DEBIAN_VARIANT}

ARG PYTHON_VERSION
ARG TARGETARCH
ARG CLOUDFLARED_VERSION=latest

LABEL org.opencontainers.image.source="https://github.com/BimxyzDev/yolks"

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl git jq ffmpeg iproute2 dnsutils iputils-ping \
      sqlite3 libsqlite3-dev build-essential libtool pkg-config \
      libffi-dev libssl-dev zlib1g-dev libjpeg-dev \
      tzdata zip unzip tar tini fonts-liberation \
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

# Build gagal kalau versi python di image tidak sama dengan yang diminta
RUN python -c "import sys; v='${PYTHON_VERSION}'; assert '%d.%d' % sys.version_info[:2] == v, 'Python %s != %s' % (sys.version, v)" \
 && python -V && pip --version

USER container
ENV USER=container \
    HOME=/home/container \
    PYTHONUNBUFFERED=1 \
    PYTHONUSERBASE=/home/container/.local \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PATH=/home/container/.local/bin:/usr/local/bin:/usr/bin:/bin

WORKDIR /home/container

COPY --chmod=755 entrypoint.sh /entrypoint.sh
COPY --chmod=755 start.sh /usr/local/bin/start.sh

ENTRYPOINT ["/usr/bin/tini", "-g", "--"]
CMD ["/bin/bash", "/entrypoint.sh"]
