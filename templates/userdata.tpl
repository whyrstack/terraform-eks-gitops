#!/bin/bash
set -e

# Update system
yum update -y

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

# Install kubectl matching EKS cluster version ${kubernetes_version}
curl -LO "https://dl.k8s.io/release/v${kubernetes_version}.0/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/


# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# Install useful tools
yum install -y git vim htop

# Configure kubectl completion
echo 'export PATH="/usr/local/bin:$PATH"' >> /home/ec2-user/.bashrc
echo 'source <(kubectl completion bash)' >> /home/ec2-user/.bashrc
echo 'alias k=kubectl' >> /home/ec2-user/.bashrc
echo 'complete -F __start_kubectl k' >> /home/ec2-user/.bashrc

# Set permissions
chown -R ec2-user:ec2-user /home/ec2-user

echo "Bastion setup complete!" > /var/log/userdata-complete.log