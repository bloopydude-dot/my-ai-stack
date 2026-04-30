provider "google" {
  project = "Yonyx-ai-stack-456789"
  region  = "us-central1"
}

resource "google_compute_instance" "ai_stack" {
  name         = "ai-stack-instance"
  machine_type = "t2a-standard-4" # Arm64
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-noble-arm64-v20240423" # Adjust to 26.04 once live
      size  = 100
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = "34.72.193.181" # Your Static IP
    }
  }

  metadata_startup_script = file("startup.sh")

  tags = ["http-server", "https-server"]
}

resource "google_compute_firewall" "allow_web" {
  name    = "allow-web-traffic"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server", "https-server"]
}

