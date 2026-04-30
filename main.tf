terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = "YOUR_PROJECT_ID"
  region  = "us-central1"
}

resource "google_compute_instance" "ai_stack" {
  name         = "ai-engine-tofu"
  machine_type = "e2-standard-4" # 16GB RAM
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 50
    }
  }

  network_interface {
    network = "default"
    access_config {} # Assigns Public IP
  }

  # This script auto-installs Onyx on the first boot
  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt-get update -y && apt-get install -y docker.io docker-compose git
    cd /home/bloopydude
    git clone --depth 1 https://github.com
    cd onyx/deployment/docker_compose
    cp env.prod.template .env
    echo "DISABLE_SECONDARY_INDEX=true" >> .env
    echo "GEN_AI_MODEL_PROVIDER=openai" >> .env
    echo "GEN_AI_API_KEY=$${GROQ_API_KEY}" >> .env
    docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d --scale opensearch=0
  EOT
}
