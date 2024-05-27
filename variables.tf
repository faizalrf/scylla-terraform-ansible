variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-east1"
}

variable "zone" {
  description = "The GCP zone"
  type        = string
  default     = "us-east1-b"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key file"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "ssh_private_public_key_path" {
  description = "Path to the SSH private key file"
  type        = string
  default     = "~/.ssh/id_ed25519"
}


