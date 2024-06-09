# This Terraform script deploys 3 nodes on GCP and opens up firewalls for ScyllaDB
# Faisal Saeed @ ScyllaDB

terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "5.32.0"
    }
  }
    required_version = ">= 1.8.0"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "random" {
  // Nothing to do here
}

resource "google_compute_instance" "scylla-node" {
  count        = 3
  name         = "faisal-scylla-node-${format("%02d", count.index + 1)}"
  machine_type = "n2-highmem-2"
  zone         = var.zone
  min_cpu_platform = "Intel Ice Lake"
  tags = ["keep", "alive", "ssh"]

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
  }
  
  boot_disk {
    initialize_params {
      image = "ubuntu-2204-lts"
      #size = 256
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

resource "google_compute_firewall" "allow_cql" {
  name    = "allow-cql-${random_id.firewall_suffix.hex}"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["9042"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["scylla"]
}

resource "google_compute_firewall" "allow_thrift" {
  name    = "allow-thrift-${random_id.firewall_suffix.hex}"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["9160"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["scylla"]
}

resource "google_compute_firewall" "allow_internode" {
  name    = "allow-internode-${random_id.firewall_suffix.hex}"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["7000", "7001"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["scylla"]
}

resource "google_compute_firewall" "allow_jmx" {
  name    = "allow-jmx-${random_id.firewall_suffix.hex}"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["7199"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["scylla"]
}

resource "google_compute_firewall" "allow_rest_api" {
  name    = "allow-rest-api-${random_id.firewall_suffix.hex}"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["10000"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["scylla"]
}

resource "google_compute_firewall" "allow_alternator" {
  name    = "allow-alternator-${random_id.firewall_suffix.hex}"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["8000"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["scylla"]
}

resource "random_id" "firewall_suffix" {
  byte_length = 2
}

output "internal_ips" {
  value = google_compute_instance.scylla-node[*].network_interface.0.network_ip
  description = "Iternal IP addresses of the instances"
}

output "public_ips" {
  value = google_compute_instance.scylla-node[*].network_interface.0.access_config.0.nat_ip
  description = "Public IP addresses of the instances"
}