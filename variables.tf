variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "asia-southeast1"
}

variable "zone" {
  description = "The GCP zone"
  type        = string
  default     = "asia-southeast1-a"
}

variable "name_prefix" {
  description = "Prefix for the instance name"
  type        = string
}

variable "node_count" {
  description = "Number of nodes"
  type        = number
}

variable "hardware_type" {
  description = "Instance type for the nodes"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key file"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}
