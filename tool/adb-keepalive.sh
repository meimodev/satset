#!/usr/bin/env bash
# Wireless-adb keepalive watchdog.
#
# macOS drops wireless-debug (mDNS) connections, which aborts long patrol runs
# mid-execute ("Device ... is not attached"). This loop re-discovers the device
# over mDNS and reconnects whenever it falls off, so a run survives Wi-Fi blips.
#
# Usage:
#   tool/adb-keepalive.sh [serial-substring]
#     serial-substring  optional filter, e.g. "1512d0ed" (xiaomi tablet).
#                       Default: reconnect every advertised tls-connect device.
#
# Run it in its own terminal (or background) BEFORE/DURING `patrol test`.
# Requires the device's "Wireless debugging" to be ON and already paired once.
set -u
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
export PATH="$ANDROID_HOME/platform-tools:$PATH"

FILTER="${1:-}"

echo "[keepalive] watching${FILTER:+ for '$FILTER'}; Ctrl-C to stop"
while true; do
  # Already connected & healthy?
  if adb devices | grep -E "device$" | grep -q "${FILTER:-.}"; then
    sleep 3
    continue
  fi
  # Re-discover via mDNS and reconnect.
  line="$(adb mdns services 2>/dev/null | grep 'tls-connect' | grep "${FILTER:-.}" | head -1)"
  if [ -n "$line" ]; then
    addr="$(echo "$line" | awk '{print $NF}')"   # ip:port
    if [ -n "$addr" ]; then
      echo "[keepalive] $(date +%H:%M:%S) reconnecting $addr"
      adb connect "$addr" >/dev/null 2>&1
    fi
  fi
  sleep 2
done
