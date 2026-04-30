# --- CONFIGURATION (ENTER YOUR KEYS HERE) ---
variable "gcp_project_id" { default = "onyx-ai-stack-456789" }
variable "groq_api_key"   { default = "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" }
variable "whop_api_key"   { default = "apik_PSqLKBpHW453q_A2043755_C_1a7de68981fff3ec611c7db8f6a502c65d52f0dd133718ec749560a3d4c70b" }
variable "static_ip"      { default = "34.72.193.181" }
# ---------------------------------------------

provider "google" {
  project = var.gcp_project_id
  region  = "us-central1"
  zone    = "us-central1-a"
}

resource "google_compute_instance" "onyx_vm" {
  name         = "onyx-prod"
  machine_type = "t2a-standard-4" # ARM64 Machine (16GB RAM)
  zone         = "us-central1-a"

  # Enable standard HTTP/HTTPS firewall tags
  tags = ["http-server", "https-server"]

  boot_disk {
    initialize_params {
      # Specifically requesting the Ubuntu ARM64 image
      image = "ubuntu-os-cloud/ubuntu-2404-lts-arm64" 
      size  = 100 # 100GB Storage
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = var.static_ip # Your reserved IP
    }
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    # Install Tools
    apt-get update -y && apt-get install -y docker.io docker-compose git
    systemctl stop postgresql || true

    # Deploy Onyx
    cd /home/ubuntu
    git clone --depth 1 https://github.com
    cd onyx/deployment/docker_compose
    cp env.prod.template .env

    # Inject Keys and Config
    echo "GEN_AI_MODEL_PROVIDER=openai" >> .env
    echo "GEN_AI_API_KEY=${var.groq_api_key}" >> .env
    echo "GEN_AI_API_ENDPOINT=https://groq.com" >> .env
    echo "WHOP_API_KEY=${var.whop_api_key}" >> .env
    echo "DISABLE_SECONDARY_INDEX=true" >> .env
    echo "DOCUMENT_INDEX_TYPE=vespa" >> .env

    # Launch ARM-compatible Stack
    docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d --scale opensearch=0
  EOT

  allow_stopping_for_update = true
}

output "vm_url" {
  value = "http://${var.static_ip}:3000"
}
