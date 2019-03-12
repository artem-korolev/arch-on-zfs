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
pacman -S gmrun xterm openbox xorg-xinit git vim opera xscreensaver xorg-setxkbmap xorg-server
#pacman -S virtualbox-guest-dkms virtualbox-guest-utils
