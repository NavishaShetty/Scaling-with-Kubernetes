#!/bin/bash

set -e  # Exit on any error

# Set locale
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

# Configuration variables
CLUSTER_NAME="k8s-scaling-cluster"
NODE_IP="70.167.32.130"
SSH_PORT="31375"
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