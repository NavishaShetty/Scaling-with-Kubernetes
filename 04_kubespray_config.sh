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

cd kubespray

# Create necessary directories
log "Creating configuration directories..."
mkdir -p inventory/${CLUSTER_NAME}/group_vars/k8s_cluster
mkdir -p inventory/${CLUSTER_NAME}/group_vars/all

# Configure cluster settings (optional customizations)
log "Configuring cluster settings..."
cat > inventory/${CLUSTER_NAME}/group_vars/k8s_cluster/addons.yml << EOF
# Addons configuration
dashboard_enabled: true
ingress_nginx_enabled: true
metallb_enabled: false
cert_manager_enabled: false
EOF

# Advanced Kubespray Configuration
log "Applying advanced Kubespray configurations..."
cat > inventory/${CLUSTER_NAME}/group_vars/k8s_cluster/k8s-cluster.yml << EOF
# Kubernetes version - compatible with Kubespray v2.20.0
kube_version: v1.26.0
kube_version_min_required: v1.26.0
download_run_once: true
download_localhost: true

# Cluster configuration
cluster_name: k8s-scaling
kube_proxy_mode: ipvs

# Network plugin
kube_network_plugin: calico

# DNS configuration
dns_mode: coredns

# Container runtime
container_manager: containerd

# Enable Helm
helm_enabled: true

# Storage
local_volume_provisioner_enabled: true

# Monitoring and logging
metrics_server_enabled: true

# Single node configuration
kube_api_server_port: 6443
supplementary_addresses_in_ssl_keys: [${NODE_IP}]

# Advanced networking
kube_service_addresses: 10.233.0.0/18
kube_pods_subnet: 10.233.64.0/18
EOF

cat > inventory/${CLUSTER_NAME}/group_vars/all/all.yml << EOF
# Enable unsafe sysctls for performance
unsafe_show_logs: true
bootstrap_os: ubuntu

# Configure container engine
containerd_version: '1.6.6'

# System optimization
system_reserved: true
system_reserved_memory: 512Mi
system_reserved_cpu: 200m

# SSH configuration for remote deployment
ansible_ssh_common_args: '-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
EOF

log "Cluster configuration completed successfully!"

# Create version.yml
cat > inventory/${CLUSTER_NAME}/group_vars/k8s_cluster/version.yml << EOF
---
kube_version: v1.26.0
kube_version_min_required: v1.26.0
container_manager: containerd
EOF