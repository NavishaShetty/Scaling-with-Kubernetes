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
# Kubernetes version
kube_version: v1.28.2

# Cluster configuration
cluster_name: k8s-scaling
kube_proxy_mode: ipvs

# Network plugin
kube_network_plugin: calico
kube_network_plugin_multus: true

# Enable features for production readiness
kube_feature_gates:
  - NodeSwap=false
  - KubeletInUserNamespace=true

# DNS configuration
dns_mode: coredns
enable_nodelocaldns: true

# Container runtime
container_manager: containerd

# Enable Helm
helm_enabled: true

# Storage
enable_csi_driver: true
local_volume_provisioner_enabled: true

# Monitoring and logging
metrics_server_enabled: true
enable_network_policy: true

# GPU support
nvidia_gpu_nodes:
  - worker1
  - worker2
  - worker3

# Advanced networking
kube_service_addresses: 10.233.0.0/18
kube_pods_subnet: 10.233.64.0/18
EOF

cat > inventory/${CLUSTER_NAME}/group_vars/all/all.yml << EOF
# Enable unsafe sysctls for performance
unsafe_show_logs: true
bootstrap_os: ubuntu

# Configure container engine
docker_version: '20.10'
containerd_version: '1.7.2'

# System optimization
system_reserved: true
system_reserved_memory: 512Mi
system_reserved_cpu: 200m

# GPU configuration
nvidia_driver_version: "525"
nvidia_container_runtime_version: "3.13.0"
EOF