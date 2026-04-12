#!/bin/sh
# Clean stale Chrome locks from previous pod runs
find "${HOME}/.openclaw/browser" -name "Singleton*" -delete 2>/dev/null || true

# Pre-start Chrome on separate port+dir to warm shared library cache
# This makes OpenClaw's own Chrome launch faster (libs in page cache)
google-chrome \
  --headless \
  --no-sandbox \
  --disable-gpu \
  --disable-dev-shm-usage \
  --remote-debugging-port=19222 \
  --user-data-dir=/tmp/chrome-warmup \
  about:blank >/dev/null 2>&1 &

# Wait for warmup Chrome to be ready
for i in $(seq 1 30); do
  if wget -q --spider "http://127.0.0.1:19222/json/version" 2>/dev/null; then
    break
  fi
  sleep 1
done

exec openclaw gateway --allow-unconfigured "$@"
