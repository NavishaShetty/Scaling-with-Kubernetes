#!/bin/bash

# =============================================================================
# SECTION 4: DEPLOY KUBERNETES USING KUBESPRAY
# =============================================================================
echo "=== SECTION 4: Deploying Kubernetes ==="

# Variables
AWS_INSTANCE_IP="3.149.236.26"
AWS_INSTANCE_PRIVATE_IP="172.31.8.149" 
SSH_KEY_PATH="~/.ssh/aws-key-pair.pem" 
SSH_USER="ubuntu"  

deploy_kubernetes() {
    echo "Starting Kubernetes deployment with Kubespray..."
    
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
    
    # Verify inventory exists
    if [ ! -f "inventory/mycluster/inventory.ini" ]; then
        echo "❌ Inventory file not found. Please run 03_configure_kubespray.sh first"
        exit 1
    fi
    
    # Test connection first
    echo "Testing connection to remote machine..."
    ansible -i inventory/mycluster/inventory.ini all -m ping --become
    
    if [ $? -ne 0 ]; then
        echo "❌ Cannot connect to remote machine. Please check:"
        echo "   - SSH connectivity: ssh -i $SSH_KEY_PATH $SSH_USER@$AWS_INSTANCE_IP"
        echo "   - Security group allows SSH (port 22)"
        echo "   - SSH key permissions: chmod 600 $SSH_KEY_PATH"
        echo "   - Instance is running in AWS console"
        return 1
    fi
    
    echo "✅ Connection test successful!"
    
    # Deploy Kubernetes cluster (modern Kubespray approach - no separate bootstrap needed)
    echo "Deploying Kubernetes cluster (this may take 15-30 minutes)..."
    echo "This will handle OS preparation and Kubernetes installation in one step..."
    
    ansible-playbook -i inventory/mycluster/inventory.ini \
        --become --become-user=root \
        cluster.yml
    
    if [ $? -eq 0 ]; then
        echo "✅ Kubernetes deployment completed successfully!"
        
        # Copy kubeconfig from remote machine
        echo "Copying kubeconfig from remote machine..."
        mkdir -p ~/.kube
        scp -i $SSH_KEY_PATH $SSH_USER@$AWS_INSTANCE_IP:/etc/kubernetes/admin.conf ~/.kube/config
        
        # Update kubeconfig to use public IP for external access
        # The cluster will use private IP internally, but we need public IP for kubectl access
        echo "Configuring kubeconfig for external access..."
        sed -i.bak "s/127.0.0.1:6443/$AWS_INSTANCE_IP:6443/g" ~/.kube/config
        sed -i.bak2 "s/172.31.13.107:6443/$AWS_INSTANCE_IP:6443/g" ~/.kube/config
        
        echo "Kubeconfig copied and configured for external access"
        echo "✅ Cluster accessible via public IP: $AWS_INSTANCE_IP:6443"
        echo ""
        echo "✅ Deployment complete! Next step: Run 05_install_kubectl.sh"
    else
        echo "❌ Kubernetes deployment failed"
        echo "Check the Ansible output above for specific errors"
        return 1
    fi
}

# Execute this function
deploy_kubernetes