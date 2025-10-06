#!/bin/bash

# ============================================================================
# LLM API Deployment Script - Phase 1
# Builds Docker image, transfers to GPU node, and deploys to Kubernetes
# ============================================================================

set -e

# Configuration - UPDATE THESE!
AWS_INSTANCE_IP="3.143.219.136"
SSH_KEY_PATH="~/.ssh/aws-key-pair.pem"
SSH_USER="ubuntu"
IMAGE_NAME="llm-api"
IMAGE_TAG="v1"
FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DOCKER_DIR="$PROJECT_ROOT/docker"
K8S_DIR="$PROJECT_ROOT/k8s-manifests"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== LLM API Deployment - Phase 1 ===${NC}"
echo ""
echo "Project root: $PROJECT_ROOT"
echo "Docker context: $DOCKER_DIR"
echo "K8s manifests: $K8S_DIR"
echo ""

# Function to check command success
check_success() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1${NC}"
    else
        echo -e "${RED}❌ $1 failed${NC}"
        exit 1
    fi
}

# Check prerequisites
echo -e "${BLUE}Checking prerequisites...${NC}"

if [ ! -f "$DOCKER_DIR/Dockerfile" ]; then
    echo -e "${RED}❌ Dockerfile not found at $DOCKER_DIR/Dockerfile${NC}"
    exit 1
fi

if [ ! -f "$DOCKER_DIR/requirements.txt" ]; then
    echo -e "${RED}❌ requirements.txt not found at $DOCKER_DIR/requirements.txt${NC}"
    exit 1
fi

if [ ! -f "$K8S_DIR/llm-deployment-v1.yaml" ]; then
    echo -e "${RED}❌ llm-deployment-v1.yaml not found at $K8S_DIR/${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All required files present${NC}"

# Step 1: Build Docker image locally
echo ""
echo -e "${BLUE}Step 1: Building Docker image locally...${NC}"
cd "$DOCKER_DIR"
docker build -t $FULL_IMAGE_NAME .
check_success "Docker image build"

# Step 2: Save Docker image to tar file
echo ""
echo -e "${BLUE}Step 2: Saving Docker image to tar file...${NC}"
cd "$PROJECT_ROOT"
docker save $FULL_IMAGE_NAME -o ${IMAGE_NAME}-${IMAGE_TAG}.tar
check_success "Docker image export"

# Step 3: Transfer image to GPU node
echo ""
echo -e "${BLUE}Step 3: Transferring image to GPU node (this may take a few minutes)...${NC}"
scp -i $SSH_KEY_PATH ${IMAGE_NAME}-${IMAGE_TAG}.tar $SSH_USER@$AWS_INSTANCE_IP:~/
check_success "Image transfer to GPU node"

# Step 4: Load image on GPU node
echo ""
echo -e "${BLUE}Step 4: Loading image on GPU node...${NC}"
ssh -i $SSH_KEY_PATH $SSH_USER@$AWS_INSTANCE_IP "
    echo 'Removing old image if exists...'
    sudo crictl rmi $FULL_IMAGE_NAME 2>/dev/null || true
    
    echo 'Importing new image...'
    sudo ctr -n k8s.io images import ${IMAGE_NAME}-${IMAGE_TAG}.tar
    
    echo 'Tagging image...'
    sudo ctr -n k8s.io images tag docker.io/library/$FULL_IMAGE_NAME $FULL_IMAGE_NAME || true
    
    echo 'Verifying image...'
    sudo crictl images | grep '$IMAGE_NAME'
    
    echo 'Cleaning up tar file...'
    rm ${IMAGE_NAME}-${IMAGE_TAG}.tar
"
check_success "Image load on GPU node"

# Step 5: Cleanup local tar file
echo ""
echo -e "${BLUE}Step 5: Cleaning up local tar file...${NC}"
rm ${IMAGE_NAME}-${IMAGE_TAG}.tar
check_success "Cleanup"

# Step 6: Deploy to Kubernetes
echo ""
echo -e "${BLUE}Step 6: Deploying to Kubernetes...${NC}"

# Apply the deployment
kubectl apply -f "$K8S_DIR/llm-deployment-v1.yaml"
check_success "Kubernetes deployment"

# Wait for rollout
echo ""
echo -e "${YELLOW}Waiting for deployment to be ready (this may take 2-3 minutes)...${NC}"
kubectl rollout status deployment/llm-api-v1 --timeout=5m
check_success "Deployment rollout"

# Step 7: Display deployment information
echo ""
echo -e "${GREEN}=== Deployment Complete! ===${NC}"
echo ""
echo "Pod Status:"
kubectl get pods -l app=llm-api
echo ""
echo "Service Information:"
kubectl get svc llm-api-service
echo ""

NODE_PORT=$(kubectl get svc llm-api-service -o jsonpath='{.spec.ports[0].nodePort}')
echo -e "${GREEN}Service accessible at: http://${AWS_INSTANCE_IP}:${NODE_PORT}${NC}"
echo ""
echo "Test commands:"
echo -e "${BLUE}# Health check${NC}"
echo "curl http://${AWS_INSTANCE_IP}:${NODE_PORT}/"
echo ""
echo -e "${BLUE}# Generate text${NC}"
echo "curl -X POST http://${AWS_INSTANCE_IP}:${NODE_PORT}/generate \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"prompt\": \"The future of AI is\", \"max_length\": 100}'"
echo ""
echo "Monitoring commands:"
echo -e "${BLUE}# View logs${NC}"
echo "kubectl logs -l app=llm-api -f"
echo ""
echo -e "${BLUE}# Check GPU usage${NC}"
echo "ssh -i $SSH_KEY_PATH $SSH_USER@$AWS_INSTANCE_IP 'nvidia-smi'"
echo ""
echo -e "${BLUE}# Describe pod${NC}"
echo "kubectl describe pod -l app=llm-api"