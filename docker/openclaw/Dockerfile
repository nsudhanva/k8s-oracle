# Custom OpenClaw Docker image for ARM64 OKE cluster
# Base: official OpenClaw 2026.4.15 (latest stable)
# Adds: Chromium browser, CLI tools, timeout patches
#
# Why custom image?
# 1. OpenClaw's base image has no browser - needed for web browsing/screenshots
# 2. Debian's chromium package works on ARM64 (Google Chrome has no ARM64 .deb)
# 3. CLI tools (gogcli, goplaces, etc.) enable Google Workspace and Maps skills
# 4. Chrome timeout patches needed because ARM64 is slower than x86
#
# Build: docker buildx build --platform linux/arm64 --no-cache -t ghcr.io/nsudhanva/openclaw:latest --push .
# GHCR package must be Public: https://github.com/users/nsudhanva/packages/container/openclaw/settings

FROM ghcr.io/openclaw/openclaw:2026.4.15

USER root

# System packages:
# - chromium: Debian's Chromium browser (not snap, works on ARM64 natively)
# - fonts-noto-*: Required for emoji and CJK text rendering in browser screenshots
# - ffmpeg: Audio/video processing for media skills (video-frames, etc.)
# - jq, ripgrep: Required by session-logs skill
# - socat: TCP proxy - used in entrypoint to expose Chrome CDP on pod IP
#   (Debian chromium ignores --remote-debugging-address=0.0.0.0, so we proxy)
# - tmux: Required by coding-agent skill
# - wget: Used in health probes and entrypoint CDP readiness checks
# - python3: Required by uv-based skills and Python tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    chromium \
    fonts-noto-color-emoji fonts-noto-cjk \
    ffmpeg jq ripgrep socat tmux wget ca-certificates curl \
    python3 python3-pip python3-venv \
    xvfb xauth dbus dbus-x11 \
    && rm -rf /var/lib/apt/lists/*

# Install uv globally, then Python 3.14 as node user (so it's accessible at runtime)
ENV UV_INSTALL_DIR="/usr/local/bin"
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# GitHub CLI - for gh skill (PR reviews, issue management, repo operations)
# Installed from GitHub's official apt repo
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && apt-get install -y gh && \
    rm -rf /var/lib/apt/lists/*

# Google Workspace CLI (gws) - replaces gogcli
# Official Google tool covering ALL Workspace APIs dynamically
# https://github.com/googleworkspace/cli
ARG TARGETARCH
RUN set -e && \
    GWS_ARCH=$([ "$TARGETARCH" = "arm64" ] && echo "aarch64" || echo "x86_64") && \
    curl -fsSL "https://github.com/googleworkspace/cli/releases/latest/download/google-workspace-cli-${GWS_ARCH}-unknown-linux-gnu.tar.gz" | tar -xzf - -C /usr/local/bin --strip-components=0 ./gws && \
    ARCH=$([ "$TARGETARCH" = "arm64" ] && echo "arm64" || echo "amd64") && \
    curl -fsSL "https://github.com/steipete/goplaces/releases/latest/download/goplaces_0.3.0_linux_${ARCH}.tar.gz" | tar -xz -C /usr/local/bin && \
    curl -fsSL "https://github.com/steipete/spogo/releases/latest/download/spogo_0.2.0_linux_${ARCH}.tar.gz" | tar -xz -C /usr/local/bin && \
    curl -fsSL "https://github.com/steipete/discrawl/releases/latest/download/discrawl_0.4.1_linux_${ARCH}.tar.gz" | tar -xz -C /usr/local/bin && \
    curl -fsSL "https://github.com/steipete/camsnap/releases/latest/download/camsnap_0.2.0_linux_${ARCH}.tar.gz" | tar -xz -C /usr/local/bin && \
    curl -fsSL "https://github.com/steipete/ordercli/releases/latest/download/ordercli_0.1.0_linux_${ARCH}.tar.gz" | tar -xz -C /usr/local/bin

# Patch Chrome CDP timeouts for ARM64 containers
# File: /app/dist/cdp.helpers-CJUeV0SO.js (hash may change with OpenClaw version)
#
# Why: OpenClaw launches Chrome in two phases:
#   1. Bootstrap phase - starts Chrome to create Default/Preferences and Local State files
#      Default timeout: CHROME_BOOTSTRAP_PREFS_TIMEOUT_MS = 10s (too short on ARM)
#      Then kills Chrome and waits: CHROME_BOOTSTRAP_EXIT_TIMEOUT_MS = 5s
#   2. Real launch - starts Chrome and polls CDP until ready
#      Default timeout: CHROME_LAUNCH_READY_WINDOW_MS = 15s (too short on ARM)
#
# On ARM64, Chrome cold-starts take 10-15s, so these timeouts cause failures.
# These patches are a BACKUP - the primary fix is Remote CDP mode in entrypoint.sh.
# But if someone disables the entrypoint or uses the managed profile directly,
# these ensure Chrome still has enough time to start.
RUN sed -i \
    -e 's/CHROME_LAUNCH_READY_WINDOW_MS = 15e3/CHROME_LAUNCH_READY_WINDOW_MS = 6e4/g' \
    -e 's/CHROME_BOOTSTRAP_PREFS_TIMEOUT_MS = 1e4/CHROME_BOOTSTRAP_PREFS_TIMEOUT_MS = 3e4/g' \
    -e 's/CHROME_BOOTSTRAP_EXIT_TIMEOUT_MS = 5e3/CHROME_BOOTSTRAP_EXIT_TIMEOUT_MS = 15e3/g' \
    /app/dist/cdp.helpers-CJUeV0SO.js

# Install Playwright's Chromium browser bundle
# Why: OpenClaw uses Playwright ON TOP of CDP for navigate, act, snapshots, PDFs.
# Without Playwright, only basic ARIA snapshots and screenshots work.
# Docs say: use bundled CLI (node /app/node_modules/...) NOT npx playwright
# See: https://docs.openclaw.ai/tools/browser → Docker section
USER node

# Install Python 3.14 as node user (so it's accessible at runtime)
RUN uv python install 3.14

ENV PLAYWRIGHT_BROWSERS_PATH=/home/node/.cache/ms-playwright
RUN node /app/node_modules/playwright-core/cli.js install chromium

# Custom entrypoint that pre-starts Chrome before OpenClaw gateway boots
# See entrypoint.sh for detailed explanation of the Remote CDP approach
USER root
COPY --chmod=755 entrypoint.sh /usr/local/bin/openclaw-entrypoint.sh
USER node
ENTRYPOINT ["/usr/local/bin/openclaw-entrypoint.sh"]
