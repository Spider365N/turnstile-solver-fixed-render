#!/bin/bash
# Robust entrypoint for Camoufox on restricted PaaS (Render, Railway, ...).
#
# - Prefer Camoufox's own headless="virtual" (isolated Xvfb managed by the
#   library). Manual Xvfb is only a fallback when HEADLESS=false.
# - Export Mozilla env vars that disable the content-process sandbox.
#   Without this, Firefox dies with:
#     Sandbox: writing /proc/self/uid_map: EPERM
#     process exited on signal 11
#   because most PaaS kernels block nested user namespaces.
set -euo pipefail

export MOZ_DISABLE_CONTENT_SANDBOX=1
export MOZ_DISABLE_GMP_SANDBOX=1
export MOZ_DISABLE_RDD_SANDBOX=1
export MOZ_DISABLE_SOCKET_PROCESS_SANDBOX=1
# Quiet the "sandbox is disabled" banner that some builds still print.
export MOZ_NO_REMOTE=1

# Ensure profile + camoufox dirs exist and are writable.
mkdir -p /tmp/ts_profile "${HOME:-/root}/.camoufox" /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix 2>/dev/null || true

# Only start a manual Xvfb when the user explicitly wants a shared display
# (HEADLESS=false). Otherwise let Camoufox headless="virtual" own the display.
if [ "${HEADLESS:-virtual}" = "false" ] || [ "${HEADLESS:-}" = "0" ] || [ "${HEADLESS:-}" = "no" ]; then
    if [ -z "${DISPLAY:-}" ]; then
        echo "[entrypoint] starting shared Xvfb on :99 (HEADLESS=false)"
        # -ac = disable access control (container has no xauth)
        Xvfb :99 -screen 0 1920x1080x24 -ac -nolisten tcp >/tmp/xvfb.log 2>&1 &
        export DISPLAY=:99
        # Wait until the display is actually accepting connections
        for i in $(seq 1 20); do
            if xdpyinfo -display :99 >/dev/null 2>&1; then
                break
            fi
            sleep 0.25
        done
    fi
fi

exec python3 -m app
