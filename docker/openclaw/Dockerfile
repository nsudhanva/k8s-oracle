FROM ghcr.io/openclaw/openclaw:2026.4.11

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    chromium \
    fonts-noto-color-emoji fonts-noto-cjk \
    ffmpeg jq ripgrep socat tmux wget ca-certificates \
    python3 python3-pip \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && apt-get install -y gh && \
    rm -rf /var/lib/apt/lists/*

ARG TARGETARCH
RUN set -e && \
    ARCH=$([ "$TARGETARCH" = "arm64" ] && echo "arm64" || echo "amd64") && \
    curl -fsSL "https://github.com/steipete/gogcli/releases/latest/download/gogcli_0.12.0_linux_${ARCH}.tar.gz" | tar -xz -C /usr/local/bin && \
    curl -fsSL "https://github.com/steipete/goplaces/releases/latest/download/goplaces_0.3.0_linux_${ARCH}.tar.gz" | tar -xz -C /usr/local/bin && \
    curl -fsSL "https://github.com/steipete/spogo/releases/latest/download/spogo_0.2.0_linux_${ARCH}.tar.gz" | tar -xz -C /usr/local/bin && \
    curl -fsSL "https://github.com/steipete/discrawl/releases/latest/download/discrawl_0.2.0_linux_${ARCH}.tar.gz" | tar -xz -C /usr/local/bin && \
    curl -fsSL "https://github.com/steipete/camsnap/releases/latest/download/camsnap_0.2.0_linux_${ARCH}.tar.gz" | tar -xz -C /usr/local/bin && \
    curl -fsSL "https://github.com/steipete/ordercli/releases/latest/download/ordercli_0.1.0_linux_${ARCH}.tar.gz" | tar -xz -C /usr/local/bin

# Patch Chrome timeouts for ARM64 containers
RUN sed -i \
    -e 's/CHROME_LAUNCH_READY_WINDOW_MS = 15e3/CHROME_LAUNCH_READY_WINDOW_MS = 6e4/g' \
    -e 's/CHROME_BOOTSTRAP_PREFS_TIMEOUT_MS = 1e4/CHROME_BOOTSTRAP_PREFS_TIMEOUT_MS = 3e4/g' \
    -e 's/CHROME_BOOTSTRAP_EXIT_TIMEOUT_MS = 5e3/CHROME_BOOTSTRAP_EXIT_TIMEOUT_MS = 15e3/g' \
    /app/dist/cdp.helpers-Cx11b16A.js

# Install Playwright browser using bundled CLI (docs say: avoid npx playwright)
USER node
ENV PLAYWRIGHT_BROWSERS_PATH=/home/node/.cache/ms-playwright
RUN node /app/node_modules/playwright-core/cli.js install chromium

USER root
COPY --chmod=755 entrypoint.sh /usr/local/bin/openclaw-entrypoint.sh
USER node
ENTRYPOINT ["/usr/local/bin/openclaw-entrypoint.sh"]
