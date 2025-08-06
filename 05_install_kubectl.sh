#!/bin/bash

# =============================================================================
# SECTION 5: INSTALL AND CONFIGURE KUBECTL
# =============================================================================
echo "=== SECTION 5: Installing and Configuring kubectl ==="

# Variables
AWS_INSTANCE_IP="3.149.236.26"
AWS_INSTANCE_PRIVATE_IP="172.31.8.149" 
SSH_KEY_PATH="~/.ssh/aws-key-pair.pem" 
SSH_USER="ubuntu" 

echo "Using SSH key: $SSH_KEY_PATH"
echo "Connecting to: $SSH_USER@$AWS_INSTANCE_IP"

# Test SSH connection first
echo "=== TESTING SSH CONNECTION ==="
ssh -i "$SSH_KEY_PATH" -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$SSH_USER@$AWS_INSTANCE_IP" "echo 'SSH connection successful!'"

if [ $? -ne 0 ]; then
    echo "❌ SSH connection failed. Please check:"
    echo "   1. SSH key exists: ls -la $SSH_KEY_PATH"
    echo "   2. SSH key permissions: chmod 600 $SSH_KEY_PATH"
    echo "   3. Instance is running in AWS console"
    echo "   4. Security group allows SSH from your IP"
    exit 1
fi

echo "✅ SSH connection successful!"

# Check if admin.conf exists and get its location
echo ""
echo "=== FINDING KUBECONFIG ON REMOTE MACHINE ==="
echo "Checking for kubeconfig files on remote machine..."

ssh -i "$SSH_KEY_PATH" "$SSH_USER@$AWS_INSTANCE_IP" "
echo 'Looking for kubeconfig files...'
sudo find /etc/kubernetes -name '*.conf' 2>/dev/null || echo 'No kubeconfig found in /etc/kubernetes'
echo ''
echo 'Checking if cluster is running...'
sudo systemctl status kubelet | head -5
echo ''
echo 'Checking for running containers...'
sudo docker ps 2>/dev/null | head -5 || sudo crictl ps 2>/dev/null | head -5 || echo 'No containers found'
"

# Try different methods to get kubeconfig
echo ""
echo "=== ATTEMPTING TO COPY KUBECONFIG ==="

# Method 1: Try direct copy with sudo
echo "Method 1: Copying admin.conf with sudo..."
ssh -i "$SSH_KEY_PATH" "$SSH_USER@$AWS_INSTANCE_IP" "sudo cat /etc/kubernetes/admin.conf" > /tmp/kubeconfig 2>/dev/null

if [ -s /tmp/kubeconfig ]; then
    echo "✅ Successfully copied kubeconfig via sudo cat"
    
    # Create kube directory and copy config
    mkdir -p ~/.kube
    cp /tmp/kubeconfig ~/.kube/config
    
    # Fix permissions
    chmod 600 ~/.kube/config
    
    # Update server address to use public IP
    echo "Updating server address for external access..."
    sed -i.bak "s|server: https://.*:6443|server: https://$AWS_INSTANCE_IP:6443|g" ~/.kube/config
    
    echo "✅ Kubeconfig configured for external access"
    
else
    echo "❌ Method 1 failed. Trying alternative method..."
    
    # Method 2: Copy to user's home directory first
    echo "Method 2: Copying via user home directory..."
    ssh -i "$SSH_KEY_PATH" "$SSH_USER@$AWS_INSTANCE_IP" "
    sudo cp /etc/kubernetes/admin.conf /home/$SSH_USER/kubeconfig
    sudo chown $SSH_USER:$SSH_USER /home/$SSH_USER/kubeconfig
    "
    
    # Now copy from user's home
    scp -i "$SSH_KEY_PATH" "$SSH_USER@$AWS_INSTANCE_IP:/home/$SSH_USER/kubeconfig" ~/.kube/config
    
    if [ -f ~/.kube/config ]; then
        echo "✅ Successfully copied kubeconfig via home directory"
        
        # Fix permissions
        chmod 600 ~/.kube/config
        
        # Update server address
        sed -i.bak "s|server: https://.*:6443|server: https://$AWS_INSTANCE_IP:6443|g" ~/.kube/config
        
        # Clean up remote file
        ssh -i "$SSH_KEY_PATH" "$SSH_USER@$AWS_INSTANCE_IP" "rm -f /home/$SSH_USER/kubeconfig"
        
    else
        echo "❌ Failed to copy kubeconfig. Cluster might not be properly deployed."
        echo ""
        echo "Let's check the cluster status on the remote machine..."
        
        ssh -i "$SSH_KEY_PATH" "$SSH_USER@$AWS_INSTANCE_IP" "
        echo '=== CLUSTER STATUS ON REMOTE MACHINE ==='
        echo 'Kubelet status:'
        sudo systemctl status kubelet --no-pager | head -10
        echo ''
        echo 'Container runtime status:'
        sudo systemctl status containerd --no-pager | head -5 2>/dev/null || sudo systemctl status docker --no-pager | head -5
        echo ''
        echo 'Kubernetes processes:'
        sudo ps aux | grep -E 'kube|etcd' | grep -v grep
        echo ''
        echo 'Available kubeconfig files:'
        sudo find /etc/kubernetes -name '*.conf' 2>/dev/null || echo 'No kubeconfig files found'
        "
        exit 1
    fi
fi

# Clean up temp file
rm -f /tmp/kubeconfig

# 🔧 FIX: Configure kubectl to skip TLS verification properly
echo ""
echo "=== CONFIGURING KUBECTL FOR CERTIFICATE COMPATIBILITY ==="
echo "Fixing certificate verification issue..."

# Backup config
cp ~/.kube/config ~/.kube/config.backup

# Use Python to fix the kubeconfig (works reliably on macOS)
python3 -c "
import re

# Read the file
with open('$HOME/.kube/config', 'r') as f:
    content = f.read()

# Remove certificate-authority-data line
content = re.sub(r'.*certificate-authority-data:.*\n', '', content)

# Ensure insecure-skip-tls-verify is true (replace false with true)
content = re.sub(r'insecure-skip-tls-verify: false', 'insecure-skip-tls-verify: true', content)

# Add insecure-skip-tls-verify if missing for cluster.local
if 'name: cluster.local' in content and 'insecure-skip-tls-verify: true' not in content.split('name: cluster.local')[1].split('name:')[0]:
    content = re.sub(r'(server: https://3\.149\.236\.26:6443)', r'\1\n    insecure-skip-tls-verify: true', content)

# Write back
with open('$HOME/.kube/config', 'w') as f:
    f.write(content)
"

echo "✅ Configured kubectl to skip TLS verification"

# Test kubectl connection
echo ""
echo "=== TESTING KUBECTL CONNECTION ==="
echo "Current kubeconfig server:"
grep "server:" ~/.kube/config

echo ""
echo "Testing cluster connection..."
kubectl cluster-info --request-timeout=10s

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ kubectl successfully connected to cluster!"
    echo ""
    
    # Display cluster information
    echo "=== CLUSTER STATUS ==="
    echo "Cluster nodes:"
    kubectl get nodes -o wide
    echo ""
    
    echo "System pods status:"
    kubectl get pods -n kube-system --no-headers | head -10
    echo ""
    
    echo "All services:"
    kubectl get services --all-namespaces
    echo ""
    
    echo "=== SUCCESS! ==="
    echo "🎉 Your Kubernetes cluster is fully accessible and ready to use!"
    echo ""
    echo "🔧 CONFIGURATION SUMMARY:"
    echo "  ✅ Network connectivity: Working (port 6443 accessible)"
    echo "  ✅ API server: Healthy and responding"
    echo "  ✅ kubectl: Configured with TLS verification bypass"
    echo "  ✅ Cluster access: Full access from your machine"
    echo ""
    echo "📂 Files created:"
    echo "  ~/.kube/config         # Main kubectl configuration"
    echo "  ~/.kube/config.backup  # Backup of original config"
    echo ""
    echo "🚀 Ready to use commands:"
    echo "  kubectl get nodes                           # Check node status"
    echo "  kubectl get pods --all-namespaces          # Check all pods"  
    echo "  kubectl create deployment test --image=nginx # Create test deployment"
    echo "  kubectl get services                        # Check services"
    echo "  kubectl apply -f your-manifest.yaml        # Deploy applications"
    
else
    echo "❌ kubectl connection failed"
    echo ""
    echo "Troubleshooting steps:"
    echo "1. Check AWS security group allows port 6443 from your IP"
    echo "2. Verify cluster is running on remote machine:"
    echo "   ssh -i $SSH_KEY_PATH $SSH_USER@$AWS_INSTANCE_IP 'sudo kubectl get nodes'"
    echo "3. Check kubeconfig content:"
    echo "   cat ~/.kube/config"
    echo "4. Restore backup if needed: cp ~/.kube/config.backup ~/.kube/config"
fi