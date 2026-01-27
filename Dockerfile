FROM node:22-slim

# System deps
RUN apt-get update \
    && apt-get install -y --no-install-recommends bash ca-certificates curl git \
    && rm -rf /var/lib/apt/lists/*

# Install MoltBot (Formerly ClawdBot) globally
RUN npm install -g clawdbot@latest

WORKDIR /root

# Declare volumes for persistence
VOLUME ["/root/.clawdbot", "/root/clawdbot"]

# Clawdbot host UI port
EXPOSE 18789
EXPOSE 18791

# Start the Gateway (MoltBot's long-running service)
CMD ["clawdbot", "gateway", "--allow-unconfigured", "--bind", "lan"]
