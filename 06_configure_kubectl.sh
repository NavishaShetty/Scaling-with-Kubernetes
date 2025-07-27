#!/bin/bash

set -e  # Exit on any error

# Configuration variables
CLUSTER_NAME="k8s-scaling-cluster"
NODE_IP="70.167.32.130"
SSH_PORT="31375"
SSH_USER="root"
SSH_KEY_PATH="~/.ssh/prime_intellect_k8s"

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

# Create .kube directory if it doesn't exist
log "Creating local .kube directory..."
mkdir -p ~/.kube

# Backup existing kubeconfig if it exists
if [ -f ~/.kube/config ]; then
    log "Backing up existing kubeconfig..."
    cp ~/.kube/config ~/.kube/config.backup.$(date +%Y%m%d_%H%M%S)
fi

# Copy kubeconfig from remote node
log "Retrieving kubeconfig from remote node..."
if scp -P ${SSH_PORT} -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${SSH_USER}@${NODE_IP}:/etc/kubernetes/admin.conf ~/.kube/config; then
    log "Kubeconfig retrieved successfully!"
else
    error "Failed to retrieve kubeconfig from remote node!"
fi

# Update server address in kubeconfig to use external IP
log "Updating kubeconfig server address..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS sed syntax
    sed -i '' "s/https:\/\/127.0.0.1:6443/https:\/\/${NODE_IP}:6443/g" ~/.kube/config
    sed -i '' "s/https:\/\/localhost:6443/https:\/\/${NODE_IP}:6443/g" ~/.kube/config
else
    # Linux sed syntax
    sed -i "s/https:\/\/127.0.0.1:6443/https:\/\/${NODE_IP}:6443/g" ~/.kube/config
    sed -i "s/https:\/\/localhost:6443/https:\/\/${NODE_IP}:6443/g" ~/.kube/config
fi

# Set proper permissions
chmod 600 ~/.kube/config

# Test kubectl access
log "Testing kubectl access..."
if kubectl get nodes; then
    log "Successfully connected to Kubernetes cluster!"
    echo ""
    log "Cluster nodes:"
    kubectl get nodes -o wide
    echo ""
    log "System pods:"
    kubectl get pods --all-namespaces
else
    error "Failed to connect to Kubernetes cluster!"
fi

echo ""
cat << EOF
${GREEN}Installation Summary:${NC}
- Kubernetes cluster deployed using Kubespray
- Kubeconfig saved to ~/.kube/config
- You can now use kubectl to manage your cluster

${YELLOW}Next steps:${NC}
1. Verify all nodes are Ready: kubectl get nodes
2. Check all pods are running: kubectl get pods -A
3. Access Kubernetes Dashboard (if enabled)
4. Deploy your applications

${YELLOW}Useful commands:${NC}
- View cluster info: kubectl cluster-info
- Get all nodes: kubectl get nodes -o wide
- Get all pods: kubectl get pods --all-namespaces

EOF

log "Script completed successfully!"