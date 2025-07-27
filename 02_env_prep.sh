#!/bin/bash

set -e  # Exit on any error

# Configuration variables
#KUBESPRAY_VERSION="v2.24.0"  # Change to desired version
CLUSTER_NAME="k8s-scaling-cluster"
#PYTHON_VERSION="3.9"

# Function definitions (you'll need to add these)
log() {
    echo "[INFO] $1"
}

warn() {
    echo "[WARN] $1"
}

# Install required tools locally with non-interactive flags
export DEBIAN_FRONTEND=noninteractive
apt update -y
apt install -y sudo
sudo apt update -y

# Add the official Ansible PPA non-interactively
apt-get update -y
apt-get install -y software-properties-common
add-apt-repository --yes --update ppa:ansible/ansible
apt-get install -y ansible

log "Starting Kubespray installation process..."

# If Kubespray already exists, remove it
if [ -d "kubespray" ]; then
    warn "kubespray directory already exists, removing it..."
    rm -rf kubespray
fi

# Clone Kubespray
git clone https://github.com/kubernetes-sigs/kubespray.git
cd kubespray

# 4. Install Python requirements
log "Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt
