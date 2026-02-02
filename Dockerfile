FROM node:22-slim

# System deps
RUN apt-get update \
    && apt-get install -y --no-install-recommends bash ca-certificates curl git \
    && rm -rf /var/lib/apt/lists/*

# Install OpenClaw (Formerly ClawdBot/MoltBot) globally
RUN npm install -g openclaw@latest

WORKDIR /root

# Declare volumes for persistence
VOLUME ["/root/.openclaw"]

# OpenClaw host UI port
EXPOSE 18789
EXPOSE 18791

# Start the Gateway (OpenClaw's long-running service)
CMD ["openclaw", "gateway", "--allow-unconfigured", "--bind", "lan"]
