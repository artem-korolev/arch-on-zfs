#!/usr/bin/env bash

source /etc/profile
export PS1="(chroot) ${PS1}"

emerge --sync
emerge app-portage/mirrorselect
emerge sys-fs/dosfstools
emerge net-misc/dhcpcd
mirrorselect -s4 -b10 -D

## nano -w /etc/locale.gen
locale-gen
eselect locale list
eselect locale set en_US.utf8
env-update && source /etc/profile && export PS1="(chroot) ${PS1}"
emerge --verbose --update --deep --newuse @world
ln -sf ../usr/share/zoneinfo/Europe/Tallinn /etc/localtime
env-update && source /etc/profile && export PS1="(chroot) ${PS1}"

#mkdir /etc/portage/package.accept_keywords
#echo "sys-fs/zfs ~amd64" >> /etc/portage/package.accept_keywords/zfs
#echo "sys-fs/zfs-kmod ~amd64" >> /etc/portage/package.accept_keywords/zfs-kmod
#echo "sys-boot/grub ~amd64" >> /etc/portage/package.accept_keywords/grub
#echo "sys-boot/grub libzfs" > /etc/portage/package.use/grub


# kernel
#echo 'sys-kernel/linux-firmware @BINARY-REDISTRIBUTABLE' >> /etc/portage/package.license
emerge -uvDN sys-kernel/gentoo-sources sys-kernel/genkernel
eselect kernel list
eselect kernel set 1
ls -l /usr/src/linux
emerge sys-apps/pciutils
cd /usr/src/linux
cp /.config ./
make && make modules_install
make install


# soft
emerge dev-vcs/git
#echo 'sys-kernel/linux-firmware @BINARY-REDISTRIBUTABLE' >> /etc/portage/package.license
#echo 'virtual/linux-sources firmware' >> /etc/portage/package.use/kernel
#emerge --ask sys-kernel/linux-firmware
emerge -v zfs
emerge -v grub:2
emerge -v sys-fs/ntfs3g
emerge -v dev-util/nvidia-cuda-toolkit
emerge -v python
emerge -v python:3.8
emerge -v app-shells/bash-completion
emerge -v x11-wm/i3
emerge -v polybar
emerge -v htop
emerge -v dmenu
emerge -v usbutils
emerge -v inotify-tools
emerge -v vscode
emerge -v sudo
emerge -v wcalc speedcrunch
emerge -v corefonts xfontsel
emerge -v qbittorrent
emerge -v gimp


emerge -v media-sound/pavucontrol media-sound/pulsemixer media-sound/paprefs media-sound/pulseaudio-modules-bt i3 openbox xorg-x11 twm xterm xclock



systemctl enable zfs.target
systemctl enable zfs-import-cache
systemctl enable zfs-mount
systemctl enable zfs-import.target

########################## SYSTEMD + ZFS
## Create a service to import /boot automatically and enable it:
cp /installation_files/zfs-import-bpool.service /etc/systemd/system/
systemctl enable zfs-import-bpool.service


########################## NETWORK
## enable network service
cp /installation_files/50-dhcp.network /etc/systemd/network/
ln -snf /run/systemd/resolve/resolv.conf /etc/resolv.conf
systemctl enable systemd-resolved.service
systemctl enable systemd-networkd.service


#mkdir /etc/portage/package.mask
#echo '>=x11-drivers/nvidia-drivers-460.67 ~amd64' > /etc/portage/package.accept_keywords/nvidia
#echo 'x11-drivers/nvidia-drivers NVIDIA-r2' >> /etc/portage/package.license

cp /grub /etc/default/grub

mount -o remount,rw /sys/firmware/efi/efivars/

emerge @module-rebuild
genkernel initramfs --kernel-config=/usr/src/linux/.config --keymap --makeopts=-j12 --mountboot --no-clean --zfs
mkdir /boot/grub
grub-mkconfig -o /boot/grub/grub.cfg
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GentooOnZFS --recheck --no-floppy
passwd
