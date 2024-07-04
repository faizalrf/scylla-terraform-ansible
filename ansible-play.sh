#!/bin/bash
# The additional command options here are to include the extra library files maintained for Scylla Ansible Role
# Faisal Saeed @ ScyllaDB
async_extra=./scylla-ansible-roles/example-playbooks/async_extra
ANSIBLE_ACTION_PLUGINS="${async_extra}"/action_plugins ansible-playbook scylla-deploy.yml -M "${async_extra}"/library