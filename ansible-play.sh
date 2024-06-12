#!/bin/bash
# This script reads the terraform output variables and generates an inventor file for Ansible
# Faisal Saeed @ ScyllaDB
async_extra=./scylla-ansible-roles/example-playbooks/async_extra
ANSIBLE_ACTION_PLUGINS="${async_extra}"/action_plugins ansible-playbook scylla-deploy.yml -M "${async_extra}"/library