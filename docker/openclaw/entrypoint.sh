#!/bin/sh
find "${HOME}/.openclaw/browser" -name "Singleton*" -delete 2>/dev/null || true

# Get pod IP (non-loopback) for Chrome CDP
POD_IP=$(hostname -i | awk '{print $1}')

mkdir -p /tmp/chrome-data
chromium --headless --no-sandbox --disable-gpu --disable-dev-shm-usage \
  --remote-debugging-port=9222 --remote-debugging-address=0.0.0.0 \
  --remote-allow-origins=* \
  --user-data-dir=/tmp/chrome-data \
  --no-first-run --no-default-browser-check \
  about:blank >/dev/null 2>&1 &

for i in $(seq 1 30); do
  if wget -q --spider "http://127.0.0.1:9222/json/version" 2>/dev/null; then
    break
  fi
  sleep 1
done

# Patch the browser profile cdpUrl with the pod's actual IP
# This makes OpenClaw treat it as remote CDP (not loopback = no local launch)
node -e "
const fs = require('fs');
const cfg = JSON.parse(fs.readFileSync('${HOME}/.openclaw/openclaw.json'));
if (cfg.browser && cfg.browser.profiles) {
  for (const p of Object.values(cfg.browser.profiles)) {
    if (p.cdpUrl) p.cdpUrl = 'http://${POD_IP}:9222';
  }
}
fs.writeFileSync('${HOME}/.openclaw/openclaw.json', JSON.stringify(cfg, null, 2));
" 2>/dev/null || true

exec openclaw gateway --allow-unconfigured "$@"
