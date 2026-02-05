FROM docker.io/cloudflare/sandbox:0.7.0

# Install Node.js 22 (required by clawdbot) + tools we need
ENV NODE_VERSION=22.13.1

RUN ARCH="$(dpkg --print-architecture)" \
    && case "${ARCH}" in \
         amd64) NODE_ARCH="x64" ;; \
         arm64) NODE_ARCH="arm64" ;; \
         *) echo "Unsupported architecture: ${ARCH}" >&2; exit 1 ;; \
       esac \
    && apt-get update \
    && apt-get install -y --no-install-recommends xz-utils ca-certificates rsync curl \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSLk "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz" -o /tmp/node.tar.xz \
    && tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1 \
    && rm /tmp/node.tar.xz \
    && node --version \
    && npm --version

# pnpm (optional, but you had it)
RUN npm install -g pnpm

# Make npm quieter + faster + less fragile in CI
# - omit optional deps to avoid a bunch of platform-specific native downloads
# - disable audit/fund noise
ENV NPM_CONFIG_AUDIT=false \
    NPM_CONFIG_FUND=false \
    NPM_CONFIG_OMIT=optional \
    NPM_CONFIG_LOGLEVEL=warn

# Install clawdbot (CLI is still named clawdbot until upstream renames)
RUN npm install -g clawdbot@2026.1.24-3 \
    && clawdbot --version

# Create moltbot directories (paths still use clawdbot until upstream renames)
RUN mkdir -p /root/.clawdbot \
    && mkdir -p /root/.clawdbot-templates \
    && mkdir -p /root/clawd/skills

# Copy startup script
COPY start-moltbot.sh /usr/local/bin/start-moltbot.sh
RUN chmod +x /usr/local/bin/start-moltbot.sh

# Copy default configuration template
COPY moltbot.json.template /root/.clawdbot-templates/moltbot.json.template

# Copy custom skills
COPY skills/ /root/clawd/skills/

WORKDIR /root/clawd
EXPOSE 18789
