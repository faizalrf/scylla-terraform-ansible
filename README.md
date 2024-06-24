# ScyllaDB with Terraform & Ansible

The purpose of this document is to set up this tool to easly deploy ScyllaDB Enterprise cluster. This uses the [ScyllaDB Ansible Role](https://github.com/scylladb/scylla-ansible-roles) to automate the deployment and configuration of the ScyllaDB following the best practices and tuning so that the user don't have to worry about those.

## Preperation

To use this ansible & terraform scripts we need the following pre-installed. The details are based on Linux, if using Windows, WSL2 with Ubuntu is recommended.

- Install [GCP CLI](https://cloud.google.com/sdk/docs/install)
    - Send an email to your IT admin team to get access to a GCP project
- Install the latest stable [Python](https://www.python.org/downloads/)
- Install [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- Install [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#installing-and-upgrading-ansible-with-pipx)
    - Version 6.7.0 or higher
- You should already have Git if you are here :)

Clone this git repo locally, `git clone git@github.com:faizalrf/scylla-terraform-ansible.git` and then go to the `scylla-terraform-ansible` folder and clone the ScyllaDB Ansible Role repo `git clone git@github.com:scylladb/scylla-ansible-roles.git` within this repo folder.

The folder structure should looke like this once the scylladb-ansible-role has been cloned within this repo. 

```
scylla-terraform-ansible/
├── scylladb-ansible-role/
|    ├── README.md
|    └── LICENSE
├── README.md
└── LICENSE
```

### GCP CLI Setup

By this time, it is expected that you already have access to GCP console and a project where billing has been enabled. Once ready with this, connect to GCP console and your account/project using the following two commands. During this, the default browser will open and you will have to authenticate using it as a one time setup

```
shell> gcloud auth application-default login
shell> gcloud config set project <project-name>
```

_**Note:** In this case we can use the project-id 'skilled-adapter-452'_

After successful authentication, you will be able to execute GCP CLI commands `gcloud` and list/create/modify the objects created under your account. 

Test your access through the following, this should list all the compute instancs available in your project.

```
shell> gcloud compute instances list
```

## Provisioning Hardware

Now that GCP access has been confirmed, we will use the terraform script to provision three or more compute nodes. These nodes will be used by the ansible, later on, for setting up as ScyllaDB cluster.

Review the `main.tf` It has the following **two** primary resource blocks, one of them creates GCP compute instances based on the configuration defined in the `terraform.tfvars` file and the other block creates firewall rules to open up necessary ports for `cqlsh` and other operations.

The `terraform.tfvars` has the following configuration

```
project_id = "skilled-adapter-452"
region     = "asia-southeast1"
zone       = "asia-southeast1-a"
node_count = 3
hardware_type = "n2-highmem-2"
name_prefix = "faisal-"
ssh_public_key_path = "~/.ssh/id_ed25519.pub"
ssh_private_public_key_path = "~/.ssh/id_ed25519"
```

The configurations are self explanatory, however, the `name_suffix` is something to add as a prefix for the ScyllaDB nodes so that they don't get mixed up with others. The `ssh` key variables point to **your** private and public keys on your computer. Pay close attention to configuring those, without these, you and **ansible** won't be able to `ssh` into the nodes later on.

To execute the terraform script

```
shell> terraform init
shell> terraform plan 
shell> terraform apply
```

The **`init`** is only required for the first time and not needed again unless we make changes to the `main.tf` script that requires re initializing. The **`plan`** will generate a detailed report plan of what are the items that are going to be provisioned by terraform. The **`apply`** will go ahead and apply the said plan on GCP and provision all the resources mentioned in the `main.tf` script based on the configuration defined in the variables. The `apply` phase will ask you to confirm before proceeding with the plan, type **`yes`** and press enter to execute.

Once the provisioning has been done, It will output the public and private IP addresses of all the nodes created. We can now use the public IP to connect to the nodes using `ssh ubuntu@<public-ip>` and do what we want. However, we want ScyllaDB Ansible Role to do all the work for us. For that there is just one requirement, generate an **invenventory** file that contains the list of nodes and their IP addresses 

Inventory file format must follow this stucture

```
[scylla]
<Private-IP> ansible_host=<Public-IP> dc=<Cloud-Region> rack=<Region AZ>
<Private-IP> ansible_host=<Public-IP> dc=<Cloud-Region> rack=<Region AZ>
<Private-IP> ansible_host=<Public-IP> dc=<Cloud-Region> rack=<Region AZ>
```

To make this easier, I have also provided a script that reads values from the `terraform apply` output and generates the inventory file for us.

```
shell> ./gen-inventory.sh
```

As a shortcut, you can also execute `./go.sh` to do all of the above and also generate the inventory file.

## Set up ScyllaDB Cluster

By now, we already have the compute instances available on the GCP project and firewalls already open along with SSH access using our own public and private key pairs.

Let's review the ansible defaults configuratin `ansible.cfg`

```
[defaults]
inventory = ./scylla-inventory.ini
remote_user = ubuntu
ansible_ssh_private_key_file=~/.ssh/id_ed25519
ssh_args = -o StrictHostKeyChecking=no
host_key_checking = False
timeout = 120
force_color = True
```

- `inventory` file, this is the file that gets generated by `gen-inventory.sh` script. 
- `remote_user` points to the user, used to `ssh` into the inventory nodes.
- `ansible_ssh_private_key_file` is your private key, the same that was used by terraform, earlier.
- `ssh_args` & `host_key_checking` configuration are to ensure that you don't get the prompt to add the new host to your `known_hosts`

Review the `scylla-deploy.yml` file for details as to how it's set up and how the Scylla Ansible Role is used. 

Starting from line #4, `vars:` all the configurations are related to ScyllaDB and are self explanatory. The Ansible role will automatically configure the ScyllaDB repositories and download and install the latest version

```
    scylla_version: latest
    scylla_edition: enterprise
```

The folder that contains the `scylla-deployment.yml` file also contains the folder for Scylla Ansible Roles, within that sub folder, there are multiple roles, the one we are using is the `scylla-ansible-roles/ansible-scylla-node`. Navigate to the `ansible-scylla-node/defaults/main.yml` contains all the configuration variables for ScyllaDB and are designed with decent values. These can be configured and overwridden as needed, for instance, in this example `scylla-deploy.yml` we have disabled the `ssl` configuration, but if we look inside the `defaults/main.yml` we can see, it's enabled by default. The role will automatically create SSL certs including CA cert and configure encryption of data in transit from end to end. 

The role also uses some custom code which is not available with the default ansible, for this, we need to execute the ansible-playbook with additional parameters to point to the custom library 

`./ansible-play.sh` is provided to take care of that. 

Execute the above script to deplpy a cluster based on the Terraform provisioned hardware and Scylla configuration defined and overwritten by the Scylla Ansible Role.

After the execution completes without errors. Execute `ssh ubuntu@<public-ip>` to one of your nodes and verify the Scylla cluster is up and running using `nodetool status` commands and also connect to it using `cqlsh <private-ip>` and test some CQL commands.
