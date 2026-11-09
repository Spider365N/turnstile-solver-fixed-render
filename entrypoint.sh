#!/bin/bash
# Robust entrypoint for Camoufox on restricted PaaS (Render, Railway, ...).
set -euo pipefail

export MOZ_DISABLE_CONTENT_SANDBOX=1
export MOZ_DISABLE_GMP_SANDBOX=1
export MOZ_DISABLE_RDD_SANDBOX=1
export MOZ_DISABLE_SOCKET_PROCESS_SANDBOX=1
export MOZ_NO_REMOTE=1

# Force virtual mode on Render-like environments unless user explicitly wants pure headless.
# Shared Xvfb is unreliable on these platforms (cannot open display :99 races).
if [ -z "${HEADLESS:-}" ] || [ "${HEADLESS}" = "false" ] || [ "${HEADLESS}" = "0" ] || [ "${HEADLESS}" = "no" ] || [ "${HEADLESS}" = "headed" ]; then
    export HEADLESS=virtual
    echo "[entrypoint] forcing HEADLESS=virtual (shared Xvfb is unreliable on this platform)"
fi

mkdir -p /tmp/ts_profile "${HOME:-/root}/.camoufox" /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix 2>/dev/null || true

# Only start manual Xvfb if user forced HEADLESS=false after our override (rare).
if [ "${HEADLESS}" = "false" ] || [ "${HEADLESS}" = "0" ]; then
    if [ -z "${DISPLAY:-}" ]; then
        echo "[entrypoint] starting shared Xvfb on :99"
        Xvfb :99 -screen 0 1920x1080x24 -ac -nolisten tcp >/tmp/xvfb.log 2>&1 &
        export DISPLAY=:99
        for i in $(seq 1 30); do
            if xdpyinfo -display :99 >/dev/null 2>&1; then
                echo "[entrypoint] Xvfb ready"
                break
            fi
            sleep 0.2
        done
    fi
fi

exec python3 -m app
