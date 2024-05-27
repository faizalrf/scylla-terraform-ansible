provider "google" {
  project = var.project_id
  region  = var.region
}

provider "random" {
  # No configuration needed for the random provider
}

resource "google_compute_instance" "scylla-loader" {
  count        = 3  # Number of instances to create
  name         = "scylla-loader-${format("%02d", count.index + 1)}"
  machine_type = "n2-highmem-2"
  zone         = var.zone
  min_cpu_platform = "Intel Ice Lake"
  tags = ["keep", "alive", "ssh"]

  metadata = {
    ssh-keys = "root:${file(var.ssh_public_key_path)}"
  }

  boot_disk {
    initialize_params {
      image = "scylla-images/scylladb-enterprise-2024-1-2"
    }
  }

  scratch_disk {
    interface = "NVME"
  }

  network_interface {
    network = "default"

    access_config {
    }
  }
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh-${random_id.firewall_suffix.hex}"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh"]
}

resource "random_id" "firewall_suffix" {
  byte_length = 2
}
