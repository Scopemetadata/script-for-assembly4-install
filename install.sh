#!/bin/bash

# Update package repositories
sudo apt-get update -y

# Install required packages
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg software-properties-common

# Create directory for keyrings
sudo install -m 0755 -d /etc/apt/keyrings

# Download and import Docker GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository to sources.list
echo "deb [arch=\"$(dpkg --print-architecture)\" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package repositories again
sudo apt-get update -y

# Install Docker packages
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Create symbolic link for docker-compose
sudo ln -s /usr/libexec/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose

# Configure Docker to use larger address pools
echo '{
  "default-address-pools":
  [
    {"base":"172.30.0.0/16","size":24},
    {"base":"10.201.0.0/16","size":24}
  ]
}' | sudo tee /etc/docker/daemon.json > /dev/null

# Restart Docker
sudo service docker restart

# Clone the repository and set up AssemblyLine
mkdir ~/git
cd ~/git
git clone https://github.com/CybercentreCanada/assemblyline-docker-compose.git

mkdir ~/deployments
cp -R ~/git/assemblyline-docker-compose/minimal_appliance ~/deployments/assemblyline
cd ~/deployments/assemblyline

# Generate SSL certificates
openssl req -nodes -x509 -newkey rsa:4096 -keyout ~/deployments/assemblyline/config/nginx.key -out ~/deployments/assemblyline/config/nginx.crt -days 365 -subj "/C=CA/ST=Ontario/L=Ottawa/O=CCCS/CN=assemblyline.local"

# Pull Docker images
cd ~/deployments/assemblyline
sudo docker-compose pull
sudo docker-compose build
sudo docker-compose -f bootstrap-compose.yaml pull

# Start AssemblyLine containers
cd ~/deployments/assemblyline
sudo docker-compose up -d --wait
sudo docker-compose -f bootstrap-compose.yaml up
