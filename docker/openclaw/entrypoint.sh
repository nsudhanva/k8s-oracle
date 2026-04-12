#!/bin/sh
# Pre-start Chrome headless before OpenClaw gateway boots.
# On ARM64, Chrome takes 10-15s to initialize CDP. OpenClaw's internal
# browser launch timeout is ~15s which is too tight. By pre-starting
# Chrome here, CDP is already warm when the gateway tries to connect.

# Clean stale locks from previous runs
find "${HOME}/.openclaw/browser" -name "Singleton*" -delete 2>/dev/null || true

# Start Chrome headless in background on OpenClaw's default CDP port
google-chrome \
  --headless \
  --no-sandbox \
  --disable-gpu \
  --disable-dev-shm-usage \
  --remote-debugging-port=18800 \
  --user-data-dir="${HOME}/.openclaw/browser/openclaw/user-data" \
  about:blank >/dev/null 2>&1 &

# Wait for CDP to be ready (up to 30s)
for i in $(seq 1 30); do
  if wget -q --spider "http://127.0.0.1:18800/json/version" 2>/dev/null; then
    break
  fi
  sleep 1
done

# Hand off to OpenClaw's original entrypoint
exec openclaw gateway --allow-unconfigured "$@"
