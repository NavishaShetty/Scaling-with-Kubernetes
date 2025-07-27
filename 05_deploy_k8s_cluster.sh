#!/bin/bash

set -e  # Exit on any error

# Set locale
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

# Configuration variables
CLUSTER_NAME="k8s-scaling-cluster"
NODE_IP="70.167.32.130"
SSH_PORT="31375"

# Function definitions
log() {
    echo "[INFO] $1"
}

warn() {
    echo "[WARN] $1"
}

cd kubespray

# Test Ansible connectivity
log "Testing Ansible connectivity..."
ansible all -i inventory/${CLUSTER_NAME}/inventory.ini -m ping \
    --ssh-extra-args="-p ${SSH_PORT}"

# Run the Kubespray playbook
log "Starting Kubernetes cluster deployment..."
log "This may take 15-30 minutes..."

ansible-playbook -i inventory/${CLUSTER_NAME}/inventory.ini \
    --become --become-user=root \
    cluster.yml

# Monitor deployment progress
tail -f /var/log/ansible.log  # if logging is enabled