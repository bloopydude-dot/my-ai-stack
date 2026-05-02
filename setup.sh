#!/bin/bash
# 1. Install Docker & Docker Compose
apt-get update
apt-get install -y docker.io docker-compose-v2

# 2. Get the docker-compose.yml from Metadata
mkdir -p /opt/onyx
curl -H "Metadata-Flavor: Google" http://google.internal > /opt/onyx/docker-compose.yml

# 3. Launch Onyx
cd /opt/onyx
sudo docker compose up -d
