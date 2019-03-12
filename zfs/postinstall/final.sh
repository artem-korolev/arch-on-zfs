#!/bin/bash

dhclient
useradd -m artem
echo "Enter password for artem user"
passwd artem
useradd -m aur
gpasswd -a aur wheel
echo "Enter password for AUR user"
passwd aur

pacman -S linux-headers
sudo -u aur sh ./aur-sripts/install-soft.sh
pacman -S linux-hardened linux-hardened-headers
