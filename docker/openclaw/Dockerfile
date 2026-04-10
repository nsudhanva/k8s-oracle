FROM ghcr.io/openclaw/openclaw:latest

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    # Playwright/Chromium system dependencies
    libnss3 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 \
    libdbus-1-3 libxkbcommon0 libatspi2.0-0 libxcomposite1 \
    libxdamage1 libxfixes3 libxrandr2 libgbm1 libpango-1.0-0 \
    libcairo2 libasound2 libwayland-client0 xvfb \
    # Fonts for browser screenshots
    fonts-noto-color-emoji fonts-noto-cjk \
    # Media processing
    ffmpeg \
    # Utilities needed by skills
    jq ripgrep socat tmux wget ca-certificates \
    # Python for uv-based skills
    python3 python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && apt-get install -y gh && \
    rm -rf /var/lib/apt/lists/*

# Install steipete CLI tools (verified Linux ARM64 releases)
ARG TARGETARCH
RUN set -e && \
    ARCH=$([ "$TARGETARCH" = "arm64" ] && echo "arm64" || echo "amd64") && \
    # gogcli - Google Workspace (Gmail, Calendar, Drive, Docs, Sheets, Contacts)
    curl -fsSL "https://github.com/steipete/gogcli/releases/latest/download/gogcli_0.12.0_linux_${ARCH}.tar.gz" | tar -xz -C /usr/local/bin && \
    # goplaces - Google Places/Maps (search, nearby, directions)
    curl -fsSL "https://github.com/steipete/goplaces/releases/latest/download/goplaces_0.3.0_linux_${ARCH}.tar.gz" | tar -xz -C /usr/local/bin && \
    # spogo - Spotify terminal interface
    curl -fsSL "https://github.com/steipete/spogo/releases/latest/download/spogo_0.2.0_linux_${ARCH}.tar.gz" | tar -xz -C /usr/local/bin && \
    # discrawl - Discord mirror and search
    curl -fsSL "https://github.com/steipete/discrawl/releases/latest/download/discrawl_0.2.0_linux_${ARCH}.tar.gz" | tar -xz -C /usr/local/bin && \
    # camsnap - RTSP/ONVIF camera snapshots
    curl -fsSL "https://github.com/steipete/camsnap/releases/latest/download/camsnap_0.2.0_linux_${ARCH}.tar.gz" | tar -xz -C /usr/local/bin && \
    # ordercli - Food delivery order tracking
    curl -fsSL "https://github.com/steipete/ordercli/releases/latest/download/ordercli_0.1.0_linux_${ARCH}.tar.gz" | tar -xz -C /usr/local/bin

USER node

# Install Playwright Chromium and symlink to standard path
ENV PLAYWRIGHT_BROWSERS_PATH=/home/node/.cache/ms-playwright
RUN npx playwright install chromium

USER root
RUN CHROME_PATH=$(find /home/node/.cache/ms-playwright -name chrome -path "*/chrome-linux/chrome" | head -1) && \
    ln -sf "$CHROME_PATH" /usr/bin/chromium && \
    ln -sf "$CHROME_PATH" /usr/bin/google-chrome
USER node
