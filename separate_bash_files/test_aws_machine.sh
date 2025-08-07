18.226.186.119
#!/bin/bash
echo "=== AWS GPU INSTANCE INFO ==="
echo "Host: $(hostname)"
echo "User: $(whoami)"
echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo "Kernel: $(uname -r)"
echo "CPU: $(lscpu | grep 'Model name' | cut -d':' -f2 | xargs)"
echo "Memory: $(free -h | grep Mem | awk '{print $2}')"
echo "Disk Space: $(df -h / | tail -1 | awk '{print $4 " available of " $2}')"
echo ""

echo "=== AWS INSTANCE METADATA ==="
if command -v curl >/dev/null 2>&1; then
    echo "Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null || echo 'Not available')"
    echo "Instance Type: $(curl -s http://169.254.169.254/latest/meta-data/instance-type 2>/dev/null || echo 'Not available')"
    echo "Public IP: $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo 'Not available')"
    echo "Private IP: $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4 2>/dev/null || echo 'Not available')"
fi
echo ""

echo "=== GPU INFO ==="
if command -v nvidia-smi >/dev/null 2>&1; then
    nvidia-smi --query-gpu=index,name,memory.total,memory.used --format=csv,noheader,nounits
else
    echo "NVIDIA drivers not installed or not available"
    lspci | grep -i nvidia || echo "No NVIDIA GPU detected"
fi