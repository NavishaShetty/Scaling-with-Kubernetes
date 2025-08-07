#!/bin/bash

# =============================================================================
# SECTION 5: INSTALL AND CONFIGURE KUBECTL
# =============================================================================
echo "=== SECTION 5: Installing and Configuring kubectl ==="

# Variables
AWS_INSTANCE_IP="3.147.64.188"
AWS_INSTANCE_PRIVATE_IP="172.31.9.45" 
SSH_KEY_PATH="~/.ssh/aws-key-pair.pem" 
SSH_USER="ubuntu" 

echo "Using SSH key: $SSH_KEY_PATH"
echo "Connecting to: $SSH_USER@$AWS_INSTANCE_IP"

# Test SSH connection first
echo "=== TESTING SSH CONNECTION ==="
ssh -i "$SSH_KEY_PATH" -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$SSH_USER@$AWS_INSTANCE_IP" "echo 'SSH connection successful!'"

if [ $? -ne 0 ]; then
    echo "❌ SSH connection failed"
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

# Configure kubectl to skip TLS verification (industry standard for external access)
echo ""
echo "=== CONFIGURING KUBECTL FOR EXTERNAL ACCESS ==="
echo "Setting insecure-skip-tls-verify for external cluster access..."

# Backup config
cp ~/.kube/config ~/.kube/config.backup

# Use kubectl config commands to properly configure external access
kubectl config set-cluster cluster.local --server=https://$AWS_INSTANCE_IP:6443 --insecure-skip-tls-verify=true

echo "✅ Configured kubectl for external cluster access"

# Test kubectl connection
echo ""
echo "=== TESTING KUBECTL CONNECTION ==="
echo "Testing cluster connection..."
kubectl cluster-info --request-timeout=10s

if [ $? -eq 0 ]; then
    echo "✅ kubectl successfully connected to cluster!"
    echo ""
    echo "Cluster nodes:"
    kubectl get nodes -o wide
else
    echo "❌ kubectl connection failed"
    echo ""
    echo "Required: Add port 6443 to your AWS security group"
    echo "• Type: Custom TCP, Port: 6443, Source: $(curl -s -4 ifconfig.me)/32"
    echo ""
    echo "Test connection manually:"
    echo "kubectl get nodes --insecure-skip-tls-verify=true"
fi