terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = "onyx-ai-stack-456789"
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

  metadata_startup_script = file("startup.sh")

  tags = ["http-server", "https-server"]
}

resource "google_compute_firewall" "allow_http_https" {
  name    = "allow-http-https"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "81"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server", "https-server"]
}



