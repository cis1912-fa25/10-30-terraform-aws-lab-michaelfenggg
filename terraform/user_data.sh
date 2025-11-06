#!/bin/bash
# User data script to automatically deploy the webapp container on EC2 instance startup

set -e  # Exit on any error

ECR_REPOSITORY_URL="${ecr_repository_url}"

# Install Docker (Amazon Linux 2023 doesn't have it pre-installed)
dnf install -y docker

# Start Docker service
systemctl start docker
systemctl enable docker

# Add ec2-user to docker group
usermod -aG docker ec2-user

# Wait a moment for Docker to be fully ready
sleep 5

# Authenticate Docker with ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $${ECR_REPOSITORY_URL}

# Pull the latest image
docker pull $${ECR_REPOSITORY_URL}:latest

# Stop and remove any existing container with the same name (if it exists)
docker stop webapp 2>/dev/null || true
docker rm webapp 2>/dev/null || true

# Run the container
docker run -d \
  --name webapp \
  --restart unless-stopped \
  -p 80:80 \
  $${ECR_REPOSITORY_URL}:latest

# Log the deployment
echo "Webapp container deployed successfully!" >> /var/log/user-data.log

