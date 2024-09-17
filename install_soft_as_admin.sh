#!/usr/bin/env bash

# CREATING USERS
users=( artem crypto )

for i in "${users[@]}"
do
  if id "$i" &>/dev/null; then
    echo "User $i already exists, skipping."
  else
    echo "Creating ZFS dataset rpool/USERDATA/home_${i}."
    zfs create rpool/USERDATA/home_${i}
    zfs set mountpoint=/home/${i} rpool/USERDATA/home_${i}

    echo "Creating user $i."
    useradd -m -G cdrom,dip,plugdev,lpadmin,audio,plugdev,users -s /bin/bash "$i"
    chown ${i}:${i} /home/${i}
    chmod go-rwx /home/${i}
  fi
done

# PREPARATIONS (keys, utils, etc)
apt update
apt install -y curl wget lsb_release
## Vulkan SDK
wget -qO - https://packages.lunarg.com/lunarg-signing-key-pub.asc | apt-key add -
wget -qO /etc/apt/sources.list.d/lunarg-vulkan-1.3.290-$(lsb_release -cs).list https://packages.lunarg.com/vulkan/1.3.290/lunarg-vulkan-1.3.290-$(lsb_release -cs).list
## Brave browser
curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | tee /etc/apt/sources.list.d/brave-browser-release.list
## Sublime Merge
wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor | tee /etc/apt/trusted.gpg.d/sublimehq-archive.gpg > /dev/null
echo "deb https://download.sublimetext.com/ apt/stable/" | tee /etc/apt/sources.list.d/sublime-text.list
## VSCode
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" | tee /etc/apt/sources.list.d/vscode-insiders.list


## Additional codecs and fonts
add-apt-repository -y multiverse


# APPLY ALL CONFIG CHANGES AND UPDATES
apt update

# INSTALLING SOFT
apt install -y ubuntu-restricted-extras gstreamer1.0-libav gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly
apt install -y libdvd-pkg
dpkg-reconfigure libdvd-pkg
apt install -y nvidia-prime

apt install -y build-essential
apt install -y vulkan-sdk
apt install -y brave-browser
apt install -y git 
apt install -y mpv
apt install -y vkd3d-demos
apt install -y pkg-config
apt install -y libssl-dev
apt install -y htop

## Sublime Merge
apt install -y apt-transport-https
apt install -y sublime-merge

## VSCode Insiders
apt install -y code-insiders

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

