#!/usr/bin/env bash

# PREPARATIONS (keys, utils, etc)
apt update
apt install -y curl
wget -qO - http://packages.lunarg.com/lunarg-signing-key-pub.asc | sudo apt-key add -
wget -qO /etc/apt/sources.list.d/lunarg-vulkan-jammy.list  http://packages.lunarg.com/vulkan/lunarg-vulkan-jammy.list
curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" | tee /etc/apt/sources.list.d/brave-browser-release.list
apt update

# INSTALLING SOFT
apt install -y build-essential
apt install -y vulkan-sdk
apt install -y brave-browser
apt install -y git 
apt install -y mpv
apt install -y vkd3d-demos
apt install -y pkg-config
apt install -y libssl-dev

# Docker
apt install -y \
    ca-certificates \
    gnupg \
    lsb-release

mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
chmod a+r /etc/apt/keyrings/docker.gpg
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
usermod -aG docker artem
systemctl enable docker.service
systemctl enable containerd.service

# for faster applications startup
apt install -y preload
