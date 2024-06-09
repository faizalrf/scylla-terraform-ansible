# Very simple script to init, destroy, plan and apply the terraform script
# The last line gen-inventory.sh will read the IP addresses deployed by terraform and generata the ansible inventory file
# Faisal Saeed @ ScyllaDB
terraform init
terraform destroy -auto-approve
terraform plan
terraform apply -auto-approve
./gen-inventory.sh
