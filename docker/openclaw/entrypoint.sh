#!/bin/sh
# Clean stale Chrome locks
find "${HOME}/.openclaw/browser" -name "Singleton*" -delete 2>/dev/null || true

# Pre-start Chrome on port 18800 with OpenClaw's expected user-data-dir
# This is required for attachOnly mode (Solution 2 from OpenClaw docs)
mkdir -p "${HOME}/.openclaw/browser/openclaw/user-data"
google-chrome --headless --no-sandbox --disable-gpu \
  --remote-debugging-port=18800 \
  --user-data-dir="${HOME}/.openclaw/browser/openclaw/user-data" \
  about:blank >/dev/null 2>&1 &

# Wait for CDP to be ready
for i in $(seq 1 30); do
  if wget -q --spider "http://127.0.0.1:18800/json/version" 2>/dev/null; then
    break
  fi
  sleep 1
done

exec openclaw gateway --allow-unconfigured "$@"
