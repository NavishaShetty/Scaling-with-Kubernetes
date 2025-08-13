#!/bin/bash

# GPU Test Script
# Tests GPU functionality in the Kubernetes cluster

set -e

echo "=== GPU Test Script ==="

# Function to check if command succeeded
check_success() {
    if [ $? -eq 0 ]; then
        echo "✅ $1 completed successfully"
    else
        echo "❌ $1 failed"
        exit 1
    fi
}

echo ""
echo "Step 1: Verifying GPU resources are available..."
GPU_AVAILABLE=$(kubectl describe nodes | grep "nvidia.com/gpu" | grep -v "0$" | wc -l)
if [ "$GPU_AVAILABLE" -eq 0 ]; then
    echo "❌ No GPU resources available. Run gpu-deploy.sh first."
    exit 1
fi
echo "✅ GPU resources found"

# echo ""
# echo "Step 2: Creating GPU test pod..."
# cat << 'TEST_EOF' | kubectl apply -f -
# apiVersion: v1
# kind: Pod
# metadata:
#   name: gpu-test
# spec:
#   restartPolicy: Never
#   runtimeClassName: nvidia
#   containers:
#   - name: gpu-test
#     image: nvidia/cuda:12.0-base-ubuntu20.04
#     command: ["nvidia-smi"]
#     resources:
#       limits:
#         nvidia.com/gpu: 1
# TEST_EOF
# check_success "GPU test pod creation"

# echo ""
# echo "Step 3: Waiting for test pod to complete..."
# kubectl wait --for=condition=Ready pod/gpu-test --timeout=120s 2>/dev/null || true
# sleep 5

# echo ""
# echo "Step 4: Checking test pod status..."
# POD_STATUS=$(kubectl get pod gpu-test -o jsonpath='{.status.phase}')
# echo "Pod status: $POD_STATUS"

# if [ "$POD_STATUS" = "Succeeded" ] || [ "$POD_STATUS" = "Running" ]; then
#     echo ""
#     echo "Step 5: Getting nvidia-smi output from test pod..."
#     kubectl logs gpu-test
#     check_success "GPU test execution"
# else
#     echo "❌ Test pod failed. Status: $POD_STATUS"
#     echo "Pod logs:"
#     kubectl logs gpu-test 2>/dev/null || echo "No logs available"
#     echo ""
#     echo "Pod description:"
#     kubectl describe pod gpu-test
#     exit 1
# fi

# echo ""
# echo "Step 6: Checking GPU allocation..."
# echo "Current GPU allocation on nodes:"
# kubectl describe nodes | grep nvidia.com/gpu

# echo ""
# echo "Step 7: Cleaning up test pod..."
# kubectl delete pod gpu-test
# check_success "Test pod cleanup"

# echo ""
# echo "✅ GPU test completed successfully!"
# echo "Your Kubernetes cluster can successfully run GPU workloads."
