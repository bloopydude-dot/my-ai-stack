#!/bin/bash
# Install Docker
apt-get update
apt-get install -y docker.io docker-compose-v2 git

# Clone your repo
mkdir -p /opt/ai-stack
git clone https://github.com /opt/ai-stack

# Start the stack
cd /opt/ai-stack
docker compose up -d
