# 12. Configure kubectl for the user
log "Configuring kubectl..."
mkdir -p ~/.kube

# Copy kubeconfig from one of the master nodes
MASTER_NODE=$(grep -A 10 "\[kube_control_plane\]" inventory/${CLUSTER_NAME}/inventory.ini | grep -v "\[" | head -1 | awk '{print $1}')
MASTER_IP=$(grep "${MASTER_NODE}" inventory/${CLUSTER_NAME}/inventory.ini | awk -F'ansible_host=' '{print $2}' | awk '{print $1}')

SSH_USER=${SSH_USER:-ubuntu}
scp ${SSH_USER}@${MASTER_IP}:~/.kube/config ~/.kube/config || \
scp ${SSH_USER}@${MASTER_IP}:/etc/kubernetes/admin.conf ~/.kube/config

# Fix permissions
chmod 600 ~/.kube/config

# 13. Verify installation
log "Verifying Kubernetes installation..."
kubectl get nodes
kubectl get pods -A

log "Kubespray installation completed successfully!"
log "Cluster info:"
kubectl cluster-info

# 14. Display useful information
cat << EOF

${GREEN}Installation Summary:${NC}
- Kubernetes cluster deployed using Kubespray
- Kubeconfig saved to ~/.kube/config
- You can now use kubectl to manage your cluster

${YELLOW}Next steps:${NC}
1. Verify all nodes are Ready: kubectl get nodes
2. Check all pods are running: kubectl get pods -A
3. Access Kubernetes Dashboard (if enabled)
4. Deploy your applications

${YELLOW}Useful commands:${NC}
- View cluster info: kubectl cluster-info
- Get all nodes: kubectl get nodes -o wide
- Get all pods: kubectl get pods --all-namespaces
- View kubespray logs: less /tmp/kubespray.log

EOF

log "Script completed successfully!"