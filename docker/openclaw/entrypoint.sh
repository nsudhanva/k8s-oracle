#!/bin/sh
find "${HOME}/.openclaw/browser" -name "Singleton*" -delete 2>/dev/null || true

mkdir -p /tmp/chrome-data
chromium --headless --no-sandbox --disable-gpu --disable-dev-shm-usage \
  --remote-debugging-port=9222 --remote-debugging-address=127.0.0.1 \
  --user-data-dir=/tmp/chrome-data \
  --no-first-run --no-default-browser-check \
  about:blank >/dev/null 2>&1 &

for i in $(seq 1 30); do
  if wget -q --spider "http://127.0.0.1:9222/json/version" 2>/dev/null; then
    break
  fi
  sleep 1
done

exec openclaw gateway --allow-unconfigured "$@"
