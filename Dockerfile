FROM python:3.13-slim-bookworm

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONWARNINGS=ignore \
    MAX_WORKERS=4 \
    PORT=9988 \
    HEADLESS=virtual \
    # Critical for Render / restricted containers: disable Firefox content sandbox
    MOZ_DISABLE_CONTENT_SANDBOX=1 \
    MOZ_DISABLE_GMP_SANDBOX=1 \
    MOZ_DISABLE_RDD_SANDBOX=1 \
    MOZ_DISABLE_SOCKET_PROCESS_SANDBOX=1 \
    # Camoufox virtual display size (larger than default 1x1 to avoid CF detection)
    CAMOUFOX_VIRTUAL_DISPLAY_SIZE=1920x1080x24

# System deps for Camoufox / Firefox under Xvfb.
# util-linux provides setpriv (used by Camoufox virtual display on some versions).
# x11-utils / xdpyinfo used by entrypoint health-check of Xvfb.
RUN apt-get update && apt-get install -y --no-install-recommends \
        xvfb \
        x11-utils \
        dumb-init \
        ca-certificates \
        fonts-liberation \
        fonts-noto-core \
        fonts-noto-cjk \
        fonts-dejavu-core \
        libgtk-3-0 \
        libdbus-glib-1-2 \
        libxt6 \
        libasound2 \
        libx11-xcb1 \
        libxcomposite1 \
        libxdamage1 \
        libxfixes3 \
        libxrandr2 \
        libpango-1.0-0 \
        libnss3 \
        libatk1.0-0 \
        libatk-bridge2.0-0 \
        libcups2 \
        libxkbcommon0 \
        libgbm1 \
        libglib2.0-0 \
        libexpat1 \
        util-linux \
        procps \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt \
    && python -m camoufox fetch \
    && mkdir -p /root/.camoufox /tmp/ts_profile

COPY app ./app
COPY web ./web
COPY entrypoint.sh ./
RUN chmod +x entrypoint.sh

EXPOSE 9988

ENTRYPOINT ["/usr/bin/dumb-init", "--", "./entrypoint.sh"]
