# --- CONFIGURATION (ENTER YOUR KEYS HERE) ---
variable "gcp_project_id" { default = "onyx-ai-stack-456789" }
variable "groq_api_key"   { default = "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" }
variable "whop_api_key"   { default = "apik_PSqLKBpHW453q_A2043755_C_1a7de68981fff3ec611c7db8f6a502c65d52f0dd133718ec749560a3d4c70b" }
# ---------------------------------------------

provider "google" {
  project = var.gcp_project_id
  region  = "us-central1"
  zone    = "us-central1-c"
}

resource "google_compute_instance" "onyx_vm" {
  name         = "onyx-prod"
  machine_type = "e2-standard-4" # 16GB RAM
  zone         = "us-central1-c"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 50
    }
  }

  network_interface {
    network = "default"
    access_config {} # Public IP
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    # Install Core Tools
    apt-get update -y && apt-get install -y docker.io docker-compose git
    systemctl stop postgresql || true

    # Deploy Onyx
    cd /home/ubuntu
    git clone --depth 1 https://github.com
    cd onyx/deployment/docker_compose
    cp env.prod.template .env

    # Inject Keys
    echo "GEN_AI_MODEL_PROVIDER=openai" >> .env
    echo "GEN_AI_API_KEY=${var.groq_api_key}" >> .env
    echo "GEN_AI_API_ENDPOINT=https://groq.com" >> .env
    echo "WHOP_API_KEY=${var.whop_api_key}" >> .env
    echo "DISABLE_SECONDARY_INDEX=true" >> .env

    # Launch Stack
    docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d --scale opensearch=0
  EOT
}

output "vm_public_ip" {
  value = google_compute_instance.onyx_vm.network_interface.0.access_config.0.nat_ip
}
