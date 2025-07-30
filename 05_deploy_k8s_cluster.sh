#!/bin/bash

set -e  # Exit on any error

# Configuration variables
CLUSTER_NAME="k8s-scaling-cluster"
NODE_IP="201.238.124.65"
SSH_PORT="10340"
SSH_USER="root"
SSH_KEY_PATH="~/.ssh/prime_intellect_k8s"

# Function definitions
log() {
    echo "[INFO] $1"
}

warn() {
    echo "[WARN] $1"
}

error() {
    echo "[ERROR] $1"
    exit 1
}

# Activate virtual environment if it exists
if [ -d "../kubespray-venv" ]; then
    log "Activating virtual environment..."
    source ../kubespray-venv/bin/activate
fi

cd kubespray

# Final connectivity test
log "Testing final connectivity before deployment..."
if ! ansible all -i inventory/${CLUSTER_NAME}/hosts.yaml -m ping --ssh-extra-args="-o StrictHostKeyChecking=no"; then
    error "Ansible connectivity test failed. Cannot proceed with deployment."
fi

# Deploy the cluster
log "Starting Kubernetes cluster deployment..."
log "This may take 20-30 minutes..."

export ANSIBLE_HOST_KEY_CHECKING=False
ansible-playbook -i inventory/${CLUSTER_NAME}/hosts.yaml cluster.yml --become --become-user=root -v

if [ $? -eq 0 ]; then
    log "Kubernetes cluster deployment completed successfully!"
else
    error "Kubernetes cluster deployment failed!"
fi

log "Deployment script completed!"