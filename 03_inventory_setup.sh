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

# Copy sample inventory
log "Setting up inventory..."
cp -rfp inventory/sample inventory/${CLUSTER_NAME}

# Create hosts.yaml for remote deployment
log "Creating hosts.yaml for remote deployment..."
cat > inventory/${CLUSTER_NAME}/hosts.yaml << EOF
all:
  hosts:
    node1:
      ansible_host: ${NODE_IP}
      ansible_port: ${SSH_PORT}
      ansible_user: ${SSH_USER}
      ansible_ssh_private_key_file: ${SSH_KEY_PATH}
      ip: ${NODE_IP}
      access_ip: ${NODE_IP}
  children:
    kube_control_plane:
      hosts:
        node1:
    kube_node:
      hosts:
        node1:
    etcd:
      hosts:
        node1:
    k8s_cluster:
      children:
        kube_control_plane:
        kube_node:
    calico_rr:
      hosts: {}
EOF

# Also create inventory.ini for compatibility
log "Creating inventory.ini for compatibility..."
cat > inventory/${CLUSTER_NAME}/inventory.ini << EOF
[all]
node1 ansible_host=${NODE_IP} ansible_port=${SSH_PORT} ansible_user=${SSH_USER} ansible_ssh_private_key_file=${SSH_KEY_PATH} ip=${NODE_IP} etcd_member_name=etcd1

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

log "Testing SSH connectivity..."
if ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -i ~/.ssh/prime_intellect_k8s -p ${SSH_PORT} ${SSH_USER}@${NODE_IP} "echo 'SSH connection successful'"; then
    log "SSH connection successful!"
else
    warn "SSH connection failed. Please check your SSH key and node accessibility."
    exit 1
fi

log "Testing Ansible connectivity..."
ansible all -i inventory/${CLUSTER_NAME}/hosts.yaml -m ping --ssh-extra-args="-o StrictHostKeyChecking=no"

log "Inventory setup completed successfully!"