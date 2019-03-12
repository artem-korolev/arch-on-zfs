#!/bin/bash

cd
git clone https://aur.archlinux.org/zfs-dkms.git
cd zfs-dkms
sed -i 's/signed//' ./PKGBUILD
makepkg -sri
