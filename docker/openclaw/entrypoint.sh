#!/bin/sh
# OpenClaw custom entrypoint - Remote CDP browser setup
#
# PROBLEM: OpenClaw's internal Chrome launcher has a 15s timeout that's too
# short for ARM64. Even with our timeout patches (60s), the launcher produces
# zombie Chrome processes because of how it spawns and monitors the process.
#
# SOLUTION: Remote CDP mode (per OpenClaw docs "Solution 2" for Linux)
# Instead of letting OpenClaw launch Chrome, we pre-start it ourselves and
# configure OpenClaw to connect to it as a "remote" browser.
#
# HOW IT WORKS:
# 1. Start Chromium headless on 127.0.0.1:9222 (Chrome's default loopback bind)
# 2. Use socat to proxy podIP:9223 -> 127.0.0.1:9222
#    Why socat? Debian chromium ignores --remote-debugging-address=0.0.0.0
# 3. Patch openclaw.json with cdpUrl=http://podIP:9223
#    Why pod IP? OpenClaw treats 127.0.0.1/localhost as "local" and tries to
#    launch Chrome itself. A non-loopback IP triggers "Remote CDP" mode where
#    OpenClaw connects to existing Chrome without spawning a new one.
# 4. Also inject ssrfPolicy.dangerouslyAllowPrivateNetwork=true
#    Why? Pod IPs (10.244.x.x) are private addresses blocked by OpenClaw's
#    default SSRF policy. This allows the connection.
#
# REFERENCES:
# - https://docs.openclaw.ai/tools/browser-linux-troubleshooting (Solution 2)
# - https://docs.openclaw.ai/tools/browser (Remote CDP section)

# Clean stale Chrome Singleton locks from previous pod runs
# Without this, Chrome refuses to start: "profile in use by another process"
find "${HOME}/.openclaw/browser" -name "Singleton*" -delete 2>/dev/null || true

# Get the pod's non-loopback IP for Remote CDP mode
POD_IP=$(hostname -i | awk '{print $1}')

# Start Chromium headless in background
# - User data in /tmp (emptyDir, resets on restart - login sessions don't persist)
# - --no-sandbox required in containers (no kernel sandboxing support)
# - --disable-dev-shm-usage makes Chrome use /tmp instead of /dev/shm for IPC
#   (though we also mount a 1Gi tmpfs at /dev/shm as a belt-and-suspenders approach)
mkdir -p /tmp/chrome-data
chromium --headless --no-sandbox --disable-gpu --disable-dev-shm-usage \
  --remote-debugging-port=9222 \
  --user-data-dir=/tmp/chrome-data \
  --no-first-run --no-default-browser-check \
  about:blank >/dev/null 2>&1 &

# Proxy Chrome CDP from pod IP to localhost
# Needed because Debian chromium ignores --remote-debugging-address=0.0.0.0
# and only binds to 127.0.0.1. socat makes it accessible via the pod IP.
socat TCP-LISTEN:9223,fork,reuseaddr,bind=${POD_IP} TCP:127.0.0.1:9222 &

# Wait for Chrome CDP to be ready (up to 30s)
for i in $(seq 1 30); do
  if wget -q --spider "http://127.0.0.1:9222/json/version" 2>/dev/null; then
    break
  fi
  sleep 1
done

# Patch openclaw.json at runtime with pod-specific values
# The ConfigMap has a placeholder cdpUrl; we replace it with the actual pod IP.
# Also inject the SSRF policy (gateway strips it from config on startup).
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

# Hand off to OpenClaw gateway
exec openclaw gateway --allow-unconfigured "$@"
