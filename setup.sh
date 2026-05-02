#!/bin/bash
# 1. System updates and Docker Install
apt-get update
apt-get install -y docker.io docker-compose-v2

# 2. Create data directories for persistence
mkdir -p /opt/onyx/n8n/data
mkdir -p /opt/onyx/npm/data
mkdir -p /opt/onyx/npm/letsencrypt
mkdir -p /opt/onyx/onyx/db
mkdir -p /opt/onyx/uptime-kuma

# 3. Pull the compose file from VM Metadata (defined in main.tf)
curl -H "Metadata-Flavor: Google" http://google.internal > /opt/onyx/docker-compose.yml

# 4. Launch the stack
cd /opt/onyx
docker compose up -d

