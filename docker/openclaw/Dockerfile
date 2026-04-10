FROM ghcr.io/openclaw/openclaw:latest

USER root

# System packages for browser, media, and tool support
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Playwright/Chromium dependencies
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

# Install steipete CLI tools (ARM64)
ARG TARGETARCH
RUN ARCH=$([ "$TARGETARCH" = "arm64" ] && echo "arm64" || echo "x86_64") && \
    # gog - Google Workspace (Gmail, Calendar, Drive, Docs, Sheets, Contacts)
    curl -fsSL "https://github.com/steipete/gog/releases/latest/download/gog_Linux_${ARCH}.tar.gz" | tar -xz -C /usr/local/bin gog && \
    # goplaces - Google Places/Maps API (search, nearby, directions)
    curl -fsSL "https://github.com/steipete/goplaces/releases/latest/download/goplaces_Linux_${ARCH}.tar.gz" | tar -xz -C /usr/local/bin goplaces && \
    # summarize - URL to clean text summarization
    curl -fsSL "https://github.com/steipete/summarize/releases/latest/download/summarize_Linux_${ARCH}.tar.gz" | tar -xz -C /usr/local/bin summarize && \
    # bird - X/Twitter CLI
    curl -fsSL "https://github.com/steipete/bird/releases/latest/download/bird_Linux_${ARCH}.tar.gz" | tar -xz -C /usr/local/bin bird && \
    # sag - ElevenLabs text-to-speech
    curl -fsSL "https://github.com/steipete/sag/releases/latest/download/sag_Linux_${ARCH}.tar.gz" | tar -xz -C /usr/local/bin sag && \
    chmod +x /usr/local/bin/gog /usr/local/bin/goplaces /usr/local/bin/summarize /usr/local/bin/bird /usr/local/bin/sag

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && apt-get install -y gh && \
    rm -rf /var/lib/apt/lists/*

USER node

# Install Playwright Chromium (cached in image)
ENV PLAYWRIGHT_BROWSERS_PATH=/home/node/.cache/ms-playwright
RUN npx playwright install chromium
