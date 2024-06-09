variable "scylla_api_token" {
  description = "Scylla Cloud API Token"
  type        = string
  sensitive   = true
}

variable "region" {
  type = string
  default = "asia-southeast1"
  description = "GCP region to use for deployment"
}
