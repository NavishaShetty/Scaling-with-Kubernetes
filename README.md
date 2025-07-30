# Scaling-with-Kubernetes

### Project Overview
    This guide demonstrates advanced Kubernetes deployment and management using Prime Intellect GPU nodes, showcasing DevOps expertise through automated cluster provisioning, advanced networking, monitoring, and application deployment.

1. git clone repository

one time setup skip if already done:
2. set up SSH keys and store pulic and private key in config file 
3. copy public key and paste in gpu node(prime intellect in this case)

4. # Create a new virtual environment in your project directory
python3 -m venv kubespray-venv

# Activate the virtual environment
source kubespray-venv/bin/activate

# Make sure the script is executable
chmod +x 02_env_prep.sh

# Run the script
./02_env_prep.sh

5. Change Node ip and and port in inventory_setup.sh file

run ./02_env_setup

till 05_file

if you see an issue with ansible version, 
# Deactivate virtual environment if active
deactivate

# Remove existing Kubespray directory
rm -rf kubespray

# Uninstall current Ansible
brew uninstall ansible

make changes in the 02_env_setup file in line 41 and use the version compatible with your machine
