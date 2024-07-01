#!/bin/bash
# This script reads the terraform output variables and generates an inventory file for Ansible
# The variables are public and private IP addresses, REGION and the ZONES of the nodes.
# Faisal Saeed @ ScyllaDB

# Get Terraform output in JSON format
terraform_output=$(terraform output -json)

# Extract internal IPs using jq
internal_ips=$(echo "$terraform_output" | jq -r '.internal_ips.value[]')

# Extract public IPs using jq
public_ips=$(echo "$terraform_output" | jq -r '.public_ips.value[]')

# Extract region (also used as DC) using jq
region=$(echo "$terraform_output" | jq -r '.region.value')

# Extract zones (also used as RACKs) using jq
zones=$(echo "$terraform_output" | jq -r '.zones.value[]')

# Convert public_ips and zones to arrays
public_ips_array=($public_ips)
zones_array=($zones)

inventory_file=scylla-inventory.ini

counter=0

# Write the inventory header
echo "[scylla]" > "$inventory_file"

# Process each pair of internal and public IPs
for internal_ip in $internal_ips; do
  public_ip=${public_ips_array[$counter]}
  zone=${zones_array[$counter]}
  echo "$internal_ip ansible_host=$public_ip dc=$region rack=$zone" >> "$inventory_file"
  counter=$((counter + 1))
done
