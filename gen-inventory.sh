#!/bin/bash
# This script reads the terraform output variables and generates an inventor file for Ansible
# Faisal Saeed @ ScyllaDB

# Get Terraform output in JSON format
terraform_output=$(terraform output -json)

# Extract internal IPs using jq
internal_ips=$(echo "$terraform_output" | jq -r '.internal_ips.value[]')

# Extract public IPs using jq
public_ips=$(echo "$terraform_output" | jq -r '.public_ips.value[]')

# Convert public_ips to an array
public_ips_array=($public_ips)

inventory_file=scylla-inventory.ini

counter=0
# 97 is the ascii for lower case `a`, this will be the first zone
rack_suffix=97
ascii_char=$(printf "\\$(printf '%03o' "$rack_suffix")")

# Write the inventory header
echo "[scylla]" > "$inventory_file"

# Process each pair of internal and public IPs
for internal_ip in $internal_ips; do
  public_ip=${public_ips_array[$counter]}
  ascii_char=$(printf "\\$(printf '%03o' "$((rack_suffix + counter))")")
  echo "$internal_ip ansible_host=$public_ip dc=asia-southeast1 rack=rack-$ascii_char" >> "$inventory_file"
  counter=$((counter + 1))
done
