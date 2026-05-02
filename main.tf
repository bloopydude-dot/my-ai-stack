resource "google_compute_instance" "ai_stack" {
  name         = "ai-stack-n2"
  machine_type = "n2-standard-8" # N2 has the CPU instructions Onyx needs
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size  = 100
      type  = "pd-ssd"
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = var.reserved_static_ip # Plug in your reserved IP here
    }
  }

  metadata = {
    # This passes your compose file into the VM so the script can find it
    docker-compose = file("${path.module}/docker-compose.yml")
  }

  metadata_startup_script = file("${path.module}/setup.sh")

  service_account {
    scopes = ["cloud-platform"]
  }
}
