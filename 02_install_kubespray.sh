#!/bin/bash

# =============================================================================
# SECTION 2: INSTALL KUBESPRAY ON LOCAL MACOS MACHINE
# =============================================================================
echo "=== SECTION 2: Installing Kubespray on macOS ==="

# Variables
AWS_INSTANCE_IP="18.226.186.119"
AWS_INSTANCE_PRIVATE_IP="172.31.13.107" 
SSH_KEY_PATH="~/.ssh/aws-key-pair.pem" 
SSH_USER="ubuntu"

install_kubespray_macos() {
    echo "Installing prerequisites on macOS..."
    
    # Get the directory where this script is located
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
    echo "Script directory: $SCRIPT_DIR"
    
    # Install Homebrew if not present
    if ! command -v brew &> /dev/null; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    # Install Python 3 and pip
    echo "Installing Python 3..."
    brew install python3
    
    # Install git if not present
    brew install git
    
    # Change to script directory
    cd "$SCRIPT_DIR"
    
    # Check if kubespray directory exists and remove it
    if [ -d "kubespray" ]; then
        echo "Kubespray directory already exists in script directory, removing..."
        rm -rf kubespray
        echo "✅ Removed existing kubespray directory"
    fi
    
    # Clone Kubespray repository in current directory
    echo "Cloning Kubespray repository to script directory..."
    git clone https://github.com/kubernetes-sigs/kubespray.git
    
    if [ $? -eq 0 ]; then
        echo "✅ Successfully cloned Kubespray"
        cd kubespray
    else
        echo "❌ Failed to clone Kubespray"
        exit 1
    fi
    
    # Setup Python virtual environment for Kubespray
    echo "Setting up Python virtual environment..."
    
    # Create virtual environment
    python3 -m venv kubespray-venv
    
    # Activate virtual environment
    source kubespray-venv/bin/activate
    
    # Upgrade pip
    pip install --upgrade pip
    
    # Install Ansible
    echo "Installing Ansible in virtual environment..."
    pip install ansible
    
    # Install Kubespray requirements
    echo "Installing Kubespray Python requirements..."
    pip install -r requirements.txt
    
    echo "✅ Kubespray installation completed"
    echo "Current directory: $(pwd)"
    echo "Kubespray installed in: $SCRIPT_DIR/kubespray"
    echo ""
    echo "IMPORTANT: Before proceeding to section 3, run:"
    echo "cd $SCRIPT_DIR/kubespray && source kubespray-venv/bin/activate"
    
    # Verify installation
    echo ""
    echo "=== VERIFYING INSTALLATION ==="
    ansible --version
    python3 -c "import ansible; print('Ansible Python module: OK')"
    
    if [ $? -eq 0 ]; then
        echo "✅ Installation verification successful!"
        echo "You can now proceed to section 3 (configure_kubespray)"
    else
        echo "❌ Installation verification failed"
        echo "Please check the error messages above"
    fi
}

# Execute this function
install_kubespray_macos