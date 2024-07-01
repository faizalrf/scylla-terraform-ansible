# Very simple script to init, destroy, plan and apply the terraform script
# The last line gen-inventory.sh will read the IP addresses deployed by terraform and generata the ansible inventory file
# Faisal Saeed @ ScyllaDB
# Check if jq is installed
if command -v jq >/dev/null 2>&1; then
  echo "jq is installed."
else
  echo "jq is not installed. Please install it before proceeding"
  exit 1
fi

terraform init
terraform destroy -auto-approve
terraform plan
terraform apply -auto-approve
./gen-inventory.sh
