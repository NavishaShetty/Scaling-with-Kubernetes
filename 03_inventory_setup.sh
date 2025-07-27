#!/bin/bash

set -e  # Exit on any error

# Configuration variables
CLUSTER_NAME="k8s-scaling-cluster"
NODE_IP="70.167.32.130"

# Function definitions
log() {
    echo "[INFO] $1"
}

warn() {
    echo "[WARN] $1"
}

cd kubespray

# Copy sample inventory
log "Setting up inventory..."
cp -rfp inventory/sample inventory/${CLUSTER_NAME}

# Update inventory with your hosts
log "Configuring inventory..."
cat > inventory/${CLUSTER_NAME}/inventory.ini << EOF

# Replace IP addresses with your actual node IPs

[all]
node1 ansible_host=${NODE_IP} ip=${NODE_IP} etcd_member_name=etcd1

[kube_control_plane]
node1

[etcd]
node1

[kube_node]
node1

[calico_rr]

[k8s_cluster:children]
kube_control_plane
kube_node
calico_rr
EOF

warn "Please edit inventory/${CLUSTER_NAME}/inventory.ini with your actual node IP addresses!"
read -p "Press Enter after updating the inventory file, or Ctrl+C to exit..."