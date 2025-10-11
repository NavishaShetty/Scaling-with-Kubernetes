# Scaling-with-Kubernetes

## Deploying Kubernetes on AWS GPU Instance using kubespray:   
1. Get a GPU instance from AWS (g4dn.xlarge - Spot instance)
2. add custom TCP inbound rule for the Security Group for port 6443 on AWS console
3. Run install_kubernetes.sh 
    > ./ install_kubernetes.sh
4. After sucessfully instaling kubernetes, run the command to check
    > kubectl get nodes
5. Next, we need to setup GPU support on the Kubernetes cluster. Run the complete-gpu-setup.sh shell script. 
The files are executed in the following order:
complete-gpu-setup.sh (run from MacOS)
    └─> remote-gpu-setup.sh 
        └─> gpu-node-setup.sh
    └─> gpu-deploy.sh 
        └─> nvidia-device-plugin.yaml
    └─> gpu-test.sh 

> ./ complete-gpu-setup.sh

## Deploying LLM API on the Kubernetes cluster:

### To push the docker image to Github registry: 
### Only if you need to push new image to registry. Not required if image already present in the registry
- Login to GitHub Container Registry:
    > echo "YOUR_TOKEN" | docker login ghcr.io -u NavishaShetty --password-stdin
- Build the Docker image locally:
    > cd ../docker 
    > docker build --platform linux/amd64 -t ghcr.io/navishashetty/llm-api:v1 .
- Push to registry
    > docker push ghcr.io/navishashetty/llm-api:v1

go to github -> packages -> llm-api -> Settings -> change to public

# Deploy LLM application deployment and service pod
- go to k8s-manifest folder and deploy the pod
    > cd llm-app/k8s-manifests
    > kubectl apply -f llm-deployment-tinyllama-v1.yaml
    > kubectl apply -f llm-services.yaml
- Get the Nodeport of the service
    > kubectl get svc llm-api-service
- Note the Nodeport and add the port to AWS security group
    > Go to EC2 → Security Groups
    > Select your security group
    > Edit inbound rules
    > Add rule:
        Type: Custom TCP
        ex. Port: 31258
        Source: Your IP or 0.0.0.0/0
- Test the API
    # Health check
    > curl http://<NodeIP>:<NodePort>/health
    This should return: {"status":"healthy"}

    # Root endpoint
    > curl http://<NodeIP>:<NodePort>/
    This should return: {"status":"healthy","model":"TinyLlama/TinyLlama-1.1B-Chat-v1.0","device":"cuda","cuda_available":true}

    # Generate text
    > curl -X POST http://<NodeIP>:<NodePort>/generate \
        -H "Content-Type: application/json" \
        -d '{"prompt": "What is machine learning?", "max_length": 50}'

    This should return JSON with:
        generated_text: The LLM's response
        model: "TinyLlama/TinyLlama-1.1B-Chat-v1.0"
        device: "cuda"
        generation_time: How long it took

# For the UI
- Create ConfigMap with the HTML
    > cd ../scripts
- Got to line 206 of llm-chat.html file and change the IP Address and Nodeport. Then,
    > kubectl create configmap llm-ui-html --from-file=index.html=llm-chat.html
- Deply the UI service
    > kubectl apply -f llm-chat-nginx.yaml
- After deploying the UI service, run the command and get the Nodeport:
    > kubectl get svc llm-ui-service
- Add this Nodeport to AWS security group
    