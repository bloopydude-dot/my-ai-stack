# --- CONFIGURATION ---
variable "gcp_project_id" { default = "onyx-ai-stack-456789" }
variable "groq_api_key"   { default = "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" }
variable "whop_api_key"   { default = "apik_PSqLKBpHW453q_A2043755_C_1a7de68981fff3ec611c7db8f6a502c65d52f0dd133718ec749560a3d4c70b" }
variable "static_ip"      { default = "34.72.193.181" }
# ---------------------

provider "google" {
  project = var.gcp_project_id
  region  = "us-central1"
  zone    = "us-central1-b"
}

resource "google_compute_instance" "onyx_vm" {
  name         = "onyx-prod"
  machine_type = "t2a-standard-4" # 16GB ARM
  zone         = "us-central1-b"
  tags         = ["http-server", "https-server"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2604-lts-arm64" 
      size  = 100 
    }
  }

  network_interface {
    network = "default"
    access_config { nat_ip = var.static_ip }
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    # 1. Install Docker & Tools
    apt-get update -y && apt-get install -y docker.io docker-compose git
    systemctl stop postgresql || true

    # 2. Setup Onyx (EXACT SEQUENCE REQUESTED)
    cd /home/ubuntu
    rm -rf onyx
    git clone --depth 1 https://github.com/onyx-dot-app/onyx.git
    cd onyx/deployment/docker_compose
    
    # 3. Inject Config
    cp env.prod.template .env
    echo "GEN_AI_MODEL_PROVIDER=openai" >> .env
    echo "GEN_AI_API_KEY=${var.groq_api_key}" >> .env
    echo "GEN_AI_API_ENDPOINT=https://groq.com" >> .env
    echo "WHOP_API_KEY=${var.whop_api_key}" >> .env
    echo "DISABLE_SECONDARY_INDEX=true" >> .env

    # 4. Supplemental Tools (n8n, SearXNG, Kuma, Dozzle, Firecrawl, Redis, Nginx)
    cat <<EOF > docker-compose.suite.yml
    version: '3'
    services:
      n8n:
        image: n8nio/n8n:latest
        ports: ["5678:5678"]
        environment: ["N8N_ENCRYPTION_KEY=supersecret"]
        restart: always
      searxng:
        image: searxng/searxng:latest
        ports: ["8080:8080"]
        restart: always
      uptime-kuma:
        image: louislam/uptime-kuma:latest
        ports: ["3001:3001"]
        restart: always
      dozzle:
        image: amir20/dozzle:latest
        volumes: ["/var/run/docker.sock:/var/run/docker.sock"]
        ports: ["8888:8080"]
        restart: always
      firecrawl:
        image: mendableai/firecrawl:latest
        ports: ["3002:3002"]
        restart: always
      redis:
        image: redis:alpine
        restart: always
      nginx-proxy:
        image: 'jc21/nginx-proxy-manager:latest'
        ports: ['80:80', '81:81', '443:443']
        volumes: ['./npm_data:/data', './letsencrypt:/letsencrypt']
        restart: always
    EOF

    # 5. Launch Full Stack
    docker-compose -f docker-compose.yml -f docker-compose.dev.yml -f docker-compose.suite.yml up -d --scale opensearch=0
  EOT
}

