#!/bin/bash

# =============================================================================
# SECTION 3: CONFIGURE KUBESPRAY FOR AWS INSTANCE
# =============================================================================
echo "=== SECTION 3: Configuring Kubespray for AWS Instance ==="

# Variables
AWS_INSTANCE_IP="3.149.236.26"
AWS_INSTANCE_PRIVATE_IP="172.31.8.149" 
SSH_KEY_PATH="~/.ssh/aws-key-pair.pem" 
SSH_USER="ubuntu"  

configure_kubespray() {
    echo "Configuring Kubespray for single-node AWS deployment..."
    
    # Get the directory where this script is located
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
    KUBESPRAY_DIR="$SCRIPT_DIR/kubespray"
    
    # Check if kubespray directory exists
    if [ ! -d "$KUBESPRAY_DIR" ]; then
        echo "❌ Kubespray directory not found at: $KUBESPRAY_DIR"
        echo "Please run 02_install_kubespray.sh first"
        exit 1
    fi
    
    # Navigate to kubespray directory
    cd "$KUBESPRAY_DIR"
    echo "Working in: $(pwd)"
    
    # Activate virtual environment if not already active
    if [[ "$VIRTUAL_ENV" != *"kubespray-venv"* ]]; then
        echo "Activating virtual environment..."
        source kubespray-venv/bin/activate
    fi
    
    # Copy sample inventory
    echo "Creating inventory configuration..."
    cp -rfp inventory/sample inventory/mycluster
    
    # Create inventory file for single node
    cat > inventory/mycluster/inventory.ini << EOF
[all]
k8s-node1 ansible_host=$AWS_INSTANCE_IP ip=$AWS_INSTANCE_PRIVATE_IP ansible_user=$SSH_USER

[kube_control_plane]
k8s-node1

[etcd]
k8s-node1

[kube_node]
k8s-node1

[calico_rr]

[k8s_cluster:children]
kube_control_plane
kube_node
calico_rr
EOF

    # Configure SSH settings
    cat > inventory/mycluster/group_vars/all/ansible.yml << EOF
---
# Ansible settings
ansible_ssh_private_key_file: $SSH_KEY_PATH
ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
ansible_python_interpreter: /usr/bin/python3
EOF

    # Copy the default k8s-cluster.yml from sample to avoid version issues
    echo "Using default Kubernetes configuration from sample..."
    cp inventory/sample/group_vars/k8s_cluster/k8s-cluster.yml inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml
    
    # Make minimal modifications for single node
    cat >> inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml << EOF

# Single node configuration additions
# Allow scheduling pods on control plane (single node setup)
kubeadm_control_plane_endpoint: "$AWS_INSTANCE_PRIVATE_IP:6443"

# Enable metrics server
metrics_server_enabled: true

# Container runtime
container_manager: containerd
EOF

    # Configure add-ons
    cat > inventory/mycluster/group_vars/k8s_cluster/addons.yml << EOF
---
# Kubernetes addons
dashboard_enabled: false
helm_enabled: true
registry_enabled: false
local_volume_provisioner_enabled: true
cephfs_provisioner_enabled: false
rbd_provisioner_enabled: false
ingress_nginx_enabled: true
cert_manager_enabled: true
metallb_enabled: false
metrics_server_enabled: true

# Storage class
local_volume_provisioner_storage_classes:
  fast-disks:
    host_dir: /mnt/fast-disks
    mount_dir: /mnt/fast-disks
  slow-disks:
    host_dir: /mnt/slow-disks
    mount_dir: /mnt/slow-disks
EOF

    echo "✅ Kubespray configuration completed"
    echo "Configuration files created in: $KUBESPRAY_DIR/inventory/mycluster/"
    echo ""
    echo "Configuration summary:"
    echo "- Kubespray directory: $KUBESPRAY_DIR"
    echo "- Instance IP: $AWS_INSTANCE_IP"
    echo "- SSH User: $SSH_USER"
    echo "- SSH Key: $SSH_KEY_PATH"
    echo ""
    echo "Next step: Run 04_deploy_kubernetes.sh"
}

# Execute this function
configure_kubespray