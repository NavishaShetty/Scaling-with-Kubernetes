# Scaling-with-Kubernetes

## Deploying Kubernetes on AWS GPU Instance using kubespray:   
1. Get a GPU instance from AWS (g4dn.xlarge - Spot instance)
2. add custom TCP inbound rule for the Security Group for port 6443 on AWS console
3. Run install_kubernetes.sh 
> ./ install_kubernetes.sh
4. After sucessfully instaling kubernetes, run the command to check
>kubectl get nodes
5. Next, we need to setup GPU support on the Kubernetes cluster. Run the complete-gpu-setup.sh shell script. 
The files are executed in the following order:
complete-gpu-setup.sh (run from MacOS)
    └─> remote-gpu-setup.sh 
        └─> gpu-node-setup.sh
    └─> gpu-deploy.sh 
    └─> gpu-test.sh 
> ./ complete-gpu-setup.sh

