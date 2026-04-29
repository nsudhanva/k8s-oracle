#!/bin/sh
# OpenClaw custom entrypoint - Remote CDP browser with anti-detection
#
# Uses Xvfb (virtual display) + headful Chrome instead of --headless
# to avoid bot detection by sites like KAYAK, Expedia, etc.
# Headful Chrome on Xvfb produces real browser fingerprints
# (WebGL, canvas, AudioContext, plugins) that match desktop browsers.

# Clean stale Chrome locks
find "${HOME}/.openclaw/browser" -name "Singleton*" -delete 2>/dev/null || true
rm -rf /tmp/chrome-data 2>/dev/null || true

POD_IP=$(hostname -i | awk '{print $1}')

# Start virtual display (Xvfb)
export DISPLAY=:99
rm -f /tmp/.X99-lock
Xvfb :99 -screen 0 1920x1080x24 -ac -nolisten tcp >/dev/null 2>&1 &

# Wait for Xvfb to be ready (up to 10s)
for i in $(seq 1 20); do
  if xdpyinfo -display :99 >/dev/null 2>&1; then
    break
  fi
  sleep 0.5
done

# Start dbus (needed for headful Chrome in containers)
eval $(dbus-launch --sh-syntax 2>/dev/null) || true

# Get installed Chromium version for accurate user-agent
CHROME_VERSION=$(chromium --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+\.\d+' || echo "131.0.0.0")

# Launch Chrome HEADFUL (not headless) on virtual display with stealth flags
mkdir -p /tmp/chrome-data
chromium --no-sandbox --disable-gpu --disable-dev-shm-usage \
  --remote-debugging-port=9222 \
  --user-data-dir=/tmp/chrome-data \
  --no-first-run --no-default-browser-check \
  --disable-blink-features=AutomationControlled \
  --disable-infobars \
  --window-size=1920,1080 \
  --start-maximized \
  --user-agent="Mozilla/5.0 (X11; Linux aarch64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/${CHROME_VERSION} Safari/537.36" \
  --lang=en-US \
  about:blank >/tmp/chrome.log 2>&1 &

# Proxy Chrome CDP from pod IP to localhost (Remote CDP mode)
socat TCP-LISTEN:9223,fork,reuseaddr TCP:127.0.0.1:9222 &

# Wait for Chrome CDP to be ready (up to 30s)
for i in $(seq 1 30); do
  if wget -q --spider "http://127.0.0.1:9222/json/version" 2>/dev/null; then
    break
  fi
  sleep 1
done

# Patch config with pod IP and SSRF policy
node -e "
const fs = require('fs');
const cfg = JSON.parse(fs.readFileSync('${HOME}/.openclaw/openclaw.json'));
if (cfg.browser) {
  cfg.browser.ssrfPolicy = { dangerouslyAllowPrivateNetwork: true };
  if (cfg.browser.profiles) {
    for (const p of Object.values(cfg.browser.profiles)) {
      if (p.cdpUrl) p.cdpUrl = 'http://${POD_IP}:9223';
    }
  }
}
fs.writeFileSync('${HOME}/.openclaw/openclaw.json', JSON.stringify(cfg, null, 2));
" 2>/dev/null || true

exec openclaw gateway --allow-unconfigured "$@"
