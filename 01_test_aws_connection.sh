#!/bin/bash

# =============================================================================
# Kubernetes Setup with Kubespray on AWS G4DN Instance
# Execute each section one by one as indicated
# =============================================================================

AWS_INSTANCE_IP="3.149.236.26"
AWS_INSTANCE_PRIVATE_IP="172.31.8.149" 
SSH_KEY_PATH="~/.ssh/aws-key-pair.pem" 
SSH_USER="ubuntu"  

# =============================================================================
# SECTION 1: TEST AWS MACHINE CONNECTION
# =============================================================================
echo "=== SECTION 1: Testing AWS Machine Connection ==="

# Test SSH connection to AWS instance
test_aws_connection() {
    echo "Testing SSH connection to AWS instance..."
    ssh -i $SSH_KEY_PATH -o ConnectTimeout=10 -o StrictHostKeyChecking=no $SSH_USER@$AWS_INSTANCE_IP "echo 'Connection successful! Instance details:' && uname -a && free -h && df -h"
    
    if [ $? -eq 0 ]; then
        echo "✅ AWS instance is accessible"
    else
        echo "❌ Cannot connect to AWS instance. Check:"
        echo "   - Security group allows SSH (port 22)"
        echo "   - SSH key path is correct: $SSH_KEY_PATH"
        echo "   - Instance is running"
        exit 1
    fi
}

# Execute this function
test_aws_connection