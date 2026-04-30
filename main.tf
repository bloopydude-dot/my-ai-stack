provider "google" {
  project = "YOUR_PROJECT_ID"
  region  = "us-central1"
}

resource "google_compute_instance" "onyx_vm" {
  name         = "onyx-prod"
  machine_type = "e2-standard-4" # Recommended 16GB RAM
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
    apt-get update -y && apt-get install -y docker.io docker-compose git
    cd /home/ubuntu
    git clone --depth 1 https://github.com
    cd onyx/deployment/docker_compose
    # Inject keys from Spacelift environment
    echo "GEN_AI_MODEL_PROVIDER=openai" >> .env
    echo "GEN_AI_API_KEY=$${GEN_AI_API_KEY}" >> .env
    docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d --scale opensearch=0
  EOT
}

output "vm_public_ip" {
  value = google_compute_instance.onyx_vm.network_interface.0.access_config.0.nat_ip
}

