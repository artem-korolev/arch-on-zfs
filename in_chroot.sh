#!/usr/bin/env bash

source /etc/profile
export PS1="(chroot) ${PS1}"
DISK=/dev/disk/by-id/nvme-eui.0025385891502595

emerge --sync
emerge app-portage/mirrorselect
emerge net-misc/dhcpcd
#mirrorselect -s4 -b10 -D

## nano -w /etc/locale.gen
locale-gen
eselect locale list
eselect locale set en_US.utf8
env-update && source /etc/profile && export PS1="(chroot) ${PS1}"
emerge --verbose --update --deep --newuse @world
ln -sf ../usr/share/zoneinfo/Europe/Tallinn /etc/localtime
env-update && source /etc/profile && export PS1="(chroot) ${PS1}"

mkdir /etc/portage/package.accept_keywords
echo "sys-fs/zfs ~amd64" >> /etc/portage/package.accept_keywords/zfs
echo "sys-fs/zfs-kmod ~amd64" >> /etc/portage/package.accept_keywords/zfs-kmod
echo "sys-boot/grub ~amd64" >> /etc/portage/package.accept_keywords/grub
echo "sys-boot/grub libzfs" > /etc/portage/package.use/grub


# kernel
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
echo 'VIDEO_CARDS="nvidia"' >> /etc/portage/make.conf
emerge dev-vcs/git
#echo 'sys-kernel/linux-firmware @BINARY-REDISTRIBUTABLE' >> /etc/portage/package.license
#echo 'virtual/linux-sources firmware' >> /etc/portage/package.use/kernel
#emerge --ask sys-kernel/linux-firmware
emerge -v zfs
emerge -v grub:2



mkdir /etc/portage/package.mask
echo '>=x11-drivers/nvidia-drivers-460.67 ~amd64' > /etc/portage/package.mask/nvidia
echo 'x11-drivers/nvidia-drivers NVIDIA-r2' >> /etc/portage/package.license

cp /grub /etc/default/grub

mount -o remount,rw /sys/firmware/efi/efivars/

#emerge @module-rebuild
genkernel initramfs --kernel-config=/usr/src/linux/.config --keymap --makeopts=-j12 --mountboot --no-clean --zfs
mkdir /boot/grub
grub-mkconfig -o /boot/grub/grub.cfg
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GentooOnZFS --recheck --no-floppy

zfs set mountpoint=legacy bpool/BOOT/gentoo
passwd
