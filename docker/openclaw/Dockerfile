# Custom OpenClaw Docker image for ARM64 OKE cluster
# Base: official OpenClaw 2026.4.25 (latest stable)
# Adds: Chromium browser, CLI tools, timeout patches, Playwright upgrade
#
# Build: docker buildx build --platform linux/arm64 --no-cache -t ghcr.io/nsudhanva/openclaw:latest --push .
# GHCR package must be Public: https://github.com/users/nsudhanva/packages/container/openclaw/settings

FROM ghcr.io/openclaw/openclaw:2026.4.25

USER root

# System packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    chromium \
    fonts-noto-color-emoji fonts-noto-cjk \
    ffmpeg jq ripgrep socat tmux wget ca-certificates curl \
    python3 python3-pip python3-venv \
    xvfb xauth dbus dbus-x11 \
    && rm -rf /var/lib/apt/lists/*

# uv (Python package manager)
ENV UV_INSTALL_DIR="/usr/local/bin"
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Bitwarden CLI - pinned to v2026.3.0 binary (NOT npm - supply chain attack on 2026.4.0)
ARG TARGETARCH
RUN BW_ARCH=$([ "$TARGETARCH" = "arm64" ] && echo "arm64" || echo "amd64") && \
    curl -fsSL "https://github.com/bitwarden/clients/releases/download/cli-v2026.3.0/bw-linux-${BW_ARCH}-2026.3.0.zip" -o /tmp/bw.zip && \
    apt-get update && apt-get install -y --no-install-recommends unzip && \
    unzip -o /tmp/bw.zip -d /usr/local/bin && chmod +x /usr/local/bin/bw && \
    rm /tmp/bw.zip && apt-get purge -y unzip && apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

# GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && apt-get install -y gh && \
    rm -rf /var/lib/apt/lists/*

# Google Workspace CLI (gws) + steipete tools
ARG TARGETARCH
RUN set -e && \
    GWS_ARCH=$([ "$TARGETARCH" = "arm64" ] && echo "aarch64" || echo "x86_64") && \
    ARCH=$([ "$TARGETARCH" = "arm64" ] && echo "arm64" || echo "amd64") && \
    cd /tmp && \
    curl -fsSL --retry 3 -o gws.tar.gz "https://github.com/googleworkspace/cli/releases/latest/download/google-workspace-cli-${GWS_ARCH}-unknown-linux-gnu.tar.gz" && \
    tar -xzf gws.tar.gz -C /usr/local/bin --strip-components=0 ./gws && rm gws.tar.gz && \
    curl -fsSL --retry 3 -o goplaces.tar.gz "https://github.com/steipete/goplaces/releases/latest/download/goplaces_0.3.0_linux_${ARCH}.tar.gz" && \
    tar -xz -C /usr/local/bin -f goplaces.tar.gz && rm goplaces.tar.gz && \
    curl -fsSL --retry 3 -o spogo.tar.gz "https://github.com/steipete/spogo/releases/latest/download/spogo_0.2.0_linux_${ARCH}.tar.gz" && \
    tar -xz -C /usr/local/bin -f spogo.tar.gz && rm spogo.tar.gz && \
    curl -fsSL --retry 3 -o discrawl.tar.gz "https://github.com/steipete/discrawl/releases/latest/download/discrawl_0.6.0_linux_${ARCH}.tar.gz" && \
    tar -xz -C /usr/local/bin -f discrawl.tar.gz && rm discrawl.tar.gz && \
    curl -fsSL --retry 3 -o camsnap.tar.gz "https://github.com/steipete/camsnap/releases/latest/download/camsnap_0.2.0_linux_${ARCH}.tar.gz" && \
    tar -xz -C /usr/local/bin -f camsnap.tar.gz && rm camsnap.tar.gz && \
    curl -fsSL --retry 3 -o ordercli.tar.gz "https://github.com/steipete/ordercli/releases/latest/download/ordercli_0.1.0_linux_${ARCH}.tar.gz" && \
    tar -xz -C /usr/local/bin -f ordercli.tar.gz && rm ordercli.tar.gz

# Patch Chrome CDP timeouts for ARM64 (backup - primary fix is Remote CDP in entrypoint)
# File hash changes with each OpenClaw version
RUN sed -i \
    -e 's/CHROME_LAUNCH_READY_WINDOW_MS = 15e3/CHROME_LAUNCH_READY_WINDOW_MS = 6e4/g' \
    -e 's/CHROME_BOOTSTRAP_PREFS_TIMEOUT_MS = 1e4/CHROME_BOOTSTRAP_PREFS_TIMEOUT_MS = 3e4/g' \
    -e 's/CHROME_BOOTSTRAP_EXIT_TIMEOUT_MS = 5e3/CHROME_BOOTSTRAP_EXIT_TIMEOUT_MS = 15e3/g' \
    /app/dist/cdp.helpers-BGwBLp-6.js

# Upgrade playwright-core (bundled 1.59.1 lacks _snapshotForAI needed for AI snapshots)
USER node
RUN cd /app && npm install playwright-core@latest 2>/dev/null

# Install Python 3.14
RUN uv python install 3.14

# Install Playwright Chromium browser
ENV PLAYWRIGHT_BROWSERS_PATH=/home/node/.cache/ms-playwright
RUN node /app/node_modules/playwright-core/cli.js install chromium

USER root
COPY --chmod=755 entrypoint.sh /usr/local/bin/openclaw-entrypoint.sh
USER node
ENTRYPOINT ["/usr/local/bin/openclaw-entrypoint.sh"]
