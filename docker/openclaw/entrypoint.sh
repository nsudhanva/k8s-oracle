#!/bin/sh
find "${HOME}/.openclaw/browser" -name "Singleton*" -delete 2>/dev/null || true

POD_IP=$(hostname -i | awk '{print $1}')

mkdir -p /tmp/chrome-data
chromium --headless --no-sandbox --disable-gpu --disable-dev-shm-usage \
  --remote-debugging-port=9222 \
  --user-data-dir=/tmp/chrome-data \
  --no-first-run --no-default-browser-check \
  about:blank >/dev/null 2>&1 &

# Proxy CDP from pod IP to localhost (Chromium ignores --remote-debugging-address)
socat TCP-LISTEN:9223,fork,reuseaddr,bind=${POD_IP} TCP:127.0.0.1:9222 &

for i in $(seq 1 30); do
  if wget -q --spider "http://127.0.0.1:9222/json/version" 2>/dev/null; then
    break
  fi
  sleep 1
done

# Patch cdpUrl with pod IP + proxied port
node -e "
const fs = require('fs');
const cfg = JSON.parse(fs.readFileSync('${HOME}/.openclaw/openclaw.json'));
if (cfg.browser && cfg.browser.profiles) {
  for (const p of Object.values(cfg.browser.profiles)) {
    if (p.cdpUrl) p.cdpUrl = 'http://${POD_IP}:9223';
  }
}
fs.writeFileSync('${HOME}/.openclaw/openclaw.json', JSON.stringify(cfg, null, 2));
" 2>/dev/null || true

exec openclaw gateway --allow-unconfigured "$@"
