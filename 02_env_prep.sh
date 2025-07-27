#!/bin/bash

set -e  # Exit on any error

# Configuration variables
CLUSTER_NAME="k8s-scaling-cluster"

# Function definitions
log() {
    echo "[INFO] $1"
}

warn() {
    echo "[WARN] $1"
}

# Check if running on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    log "Detected macOS - installing dependencies with Homebrew..."
    
    # Install Homebrew if not present
    if ! command -v brew &> /dev/null; then
        log "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    # Install dependencies
    log "Installing Ansible..."
    brew install ansible
    
    log "Installing kubectl..."
    brew install kubectl
    
    log "Installing Python3 and pip..."
    brew install python3
    
else
    log "Installing dependencies for Linux..."
    export DEBIAN_FRONTEND=noninteractive
    apt update -y
    apt install -y sudo software-properties-common
    add-apt-repository --yes --update ppa:ansible/ansible
    apt-get install -y ansible python3-pip
fi

log "Starting Kubespray installation process..."

# If Kubespray already exists, remove it
if [ -d "kubespray" ]; then
    warn "kubespray directory already exists, removing it..."
    rm -rf kubespray
fi

# Clone Kubespray
log "Cloning Kubespray..."
git clone https://github.com/kubernetes-sigs/kubespray.git
cd kubespray

# Install Python requirements
log "Installing Python dependencies..."
pip3 install --upgrade pip
pip3 install -r requirements.txt

log "Environment preparation completed successfully!"