# This Terraform script deploys 3 nodes on GCP and opens up firewalls for ScyllaDB
# Faisal Saeed @ ScyllaDB
terraform {
  # USe the latest GCP provider
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "5.32.0"
    }
  }
    required_version = ">= 1.8.0"
}

# Google Project and Region from the default variables
provider "google" {
  project = var.project_id
  region  = var.region
}

# Random number provider 
provider "random" {
  // Nothing to do here
}

# Provision 3 nodes 
resource "google_compute_instance" "scylla-node" {
  count        = var.node_count
  name         = "${var.name_prefix}-scylla-node-${format("%02d", count.index + 1)}"
  machine_type = var.hardware_type
  zone         = var.zone
  tags = ["keep", "alive", "ssh"]
  
  # Set up te public key
  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
  }
  
  # Default boot disk from GCP, this is the pre defined disk images from GCP, search GCP if a different OS version is needed
  boot_disk {
    initialize_params {
      image = "ubuntu-2204-lts"
      #size = 256
    }
  }

  # Add on an NVMe disk, this will be used by Scylla Ansible Role for the data directory
  scratch_disk {
    interface = "NVME"
  }

  network_interface {
    network = "default"

    access_config {
    }
  }
}

# Define SSH rule
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

# Open CQL firewall, port 9042
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

# Open other required firewalls for Scylla, port 9160
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

# Open internode communication firewall, port 7001
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

# Open JMX firewall, port 7199
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

# Open REST-API firewall, port 10000
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

# Open alternator firewall, port 8000
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

# Firewall name suffix so that it does not conflict with any existing firewall name.
resource "random_id" "firewall_suffix" {
  byte_length = 2
}

# Output for Internal IP addresses
output "internal_ips" {
  value = google_compute_instance.scylla-node[*].network_interface.0.network_ip
  description = "Iternal IP addresses of the instances"
}

# Output for External/Public IP addresses
output "public_ips" {
  value = google_compute_instance.scylla-node[*].network_interface.0.access_config.0.nat_ip
  description = "Public IP addresses of the instances"
}