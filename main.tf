terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = "us-central1"
}

resource "google_compute_instance" "ai_stack" {
  name         = "ai-stack-arm"
  machine_type = "t2a-standard-4"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-arm64" 
      size  = 100
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = "34.72.193.181" 
    }
  }

  # This puts the script directly in the file so it can't go missing
  metadata_startup_script = <<-EOT
    #!/bin/bash
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y ca-certificates curl gnupg git
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://docker.com | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://docker.com $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    mkdir -p /opt/ai-stack
    git clone https://github.com /opt/ai-stack
    cd /opt/ai-stack
    docker compose up -d
  EOT

  tags = ["http-server", "https-server"]
}

resource "google_compute_firewall" "allow_web" {
  name    = "allow-web-traffic"
  network = "default"
  allow {
    protocol = "tcp"
    ports    = ["80", "443", "81"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server", "https-server"]
}


