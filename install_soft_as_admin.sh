#!/usr/bin/env bash

# CREATING USERS
users=( artem crypto )
# ALLOW PARTICULAR NON-ADMIN USERS TO CONFIGURE WIFI WITHOUT ADMIN PASSWORD
wifi_users=( artem )

for i in "${users[@]}"
do
  useradd -m -G cdrom,dip,plugdev,lpadmin,lxd,sambashare -s /bin/bash -d /home/$i $i
  chown -R $i:root /home/$i
  chmod -R a-x /home/$i
  chmod -R u=rwX /home/$i
  chmod -R go-rwx /home/$i
done

# ALLOW PARTICULAR NON-ADMIN USERS TO CONFIGURE WIFI WITHOUT ADMIN PASSWORD
addgroup wifi-users
for wifi_user in "${wifi_users[@]}"
do
  usermod -a -G wifi-users $wifi_user
done
echo "[Enable NetworkManager]
Identity=unix-group:wifi-users
Action=org.freedesktop.NetworkManager.*
ResultAny=no
ResultInactive=no
ResultActive=yes" > /etc/polkit-1/localauthority/50-local.d/org.freedesktop.NetworkManager.pkla

# PREPARATIONS (keys, utils, etc)
apt update
apt install -y curl
## Vulkan SDK
wget -qO - http://packages.lunarg.com/lunarg-signing-key-pub.asc | apt-key add -
wget -qO /etc/apt/sources.list.d/lunarg-vulkan-jammy.list http://packages.lunarg.com/vulkan/lunarg-vulkan-jammy.list
## Brave browser
curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" | tee /etc/apt/sources.list.d/brave-browser-release.list
## Sublime Merge
wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor | tee /etc/apt/trusted.gpg.d/sublimehq-archive.gpg > /dev/null
echo "deb https://download.sublimetext.com/ apt/stable/" | tee /etc/apt/sources.list.d/sublime-text.list

# APPLY ALL CONFIG CHANGES AND UPDATES
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

## Sublime Merge
apt install -y apt-transport-https
apt install -y sublime-merge

## Docker
apt install -y \
    ca-certificates \
    gnupg \
    lsb-release

mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
chmod a+r /etc/apt/keyrings/docker.gpg
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
usermod -aG docker artem
systemctl enable docker.service
systemctl enable containerd.service

# for faster applications startup
apt install -y preload
