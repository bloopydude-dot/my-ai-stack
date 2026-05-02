resource "google_compute_instance" "ai_stack" {
  name         = "ai-stack-n2"
  machine_type = "n2-standard-8" # 8 vCPUs, 32GB RAM
  zone         = var.zone
  tags         = ["ai-stack-node"] # Tag used by the firewall rules

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size  = 150 # Increased for search indexes and logs
      type  = "pd-ssd"
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = var.reserved_static_ip
    }
  }

  metadata = {
    docker-compose = file("${path.module}/docker-compose.yml")
  }

  metadata_startup_script = file("${path.module}/setup.sh")
}

resource "google_compute_firewall" "ai_stack_firewall" {
  name    = "allow-ai-stack-ports"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = [
      "80",   # Nginx (HTTP)
      "443",  # Nginx (HTTPS)
      "81",   # Nginx Admin
      "3000", # Onyx Web
      "3001", # Uptime Kuma
      "3002", # Firecrawl
      "5678", # n8n
      "8080", # SearXNG (Host Port)
      "8081", # Vespa (Host Port)
      "8082", # Onyx API (Host Port)
      "8888", # Dozzle
      "9000", # Onyx Model Server
      "9200"  # OpenSearch
    ]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ai-stack-node"]
}

