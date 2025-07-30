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
    log "Installing Python3 and kubectl..."
    brew install python3 kubectl

    # Create virtual environment for the project
    log "Creating Python virtual environment..."
    python3 -m venv kubespray-venv
    source kubespray-venv/bin/activate

    # Install compatible Ansible version
    log "Installing compatible Ansible version..."
    pip install ansible==2.10.7

    # Install kubernetes package for version comparison
    pip install "kubernetes>=12.0.0"
    
else
    log "Installing dependencies for Linux..."
    export DEBIAN_FRONTEND=noninteractive
    apt update -y
    apt install -y sudo software-properties-common python3-venv python3-pip
    python3 -m venv kubespray-venv
    source kubespray-venv/bin/activate
    pip install ansible==2.10.7
    pip install "kubernetes>=12.0.0"

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

# Install Python requirements within the virtual environment
log "Installing Python dependencies..."
pip install -r requirements.txt

log "Environment preparation completed successfully!"