#!/bin/bash

ln -sf /usr/share/zoneinfo/Europe/Tallinn /etc/localtime
hwclock --systohc
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sed -i 's/^#en_US ISO-8859-1/en_US ISO-8859-1/' /etc/locale.gen
sed -i 's/^#et_EE.UTF-8 UTF-8/et_EE.UTF-8 UTF-8/' /etc/locale.gen
sed -i 's/^#et_EE ISO-8859-1/et_EE ISO-8859-1/' /etc/locale.gen
sed -i 's/^#ru_RU.KOI8-R KOI8-R/ru_RU.KOI8-R KOI8-R/' /etc/locale.gen
sed -i 's/^#ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/' /etc/locale.gen
sed -i 's/^#ru_RU ISO-8859-5/ru_RU ISO-8859-5/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "KEYMAP=us" >> /etc/vconsole.conf
echo "archlinux" >> /etc/hostname
echo -e "\n127.0.0.1	localhost\n::1		localhost\n127.0.1.1	archlinux.localdomain	archlinux\n" >> /etc/hosts
cp /etc/mkinitcpio.conf /etc/mkinitcpio.conf.original
sed -i -E 's/^HOOKS=\(.+\)$/HOOKS=(base udev autodetect modconf block keyboard zfs filesystems)/' /etc/mkinitcpio.conf

echo -e "\n[archzfs]\nSigLevel = Optional TrustAll\nServer = http://archzfs.com/\$repo/x86_64\n" >> /etc/pacman.conf
mkinitcpio -p linux
umount /dev/sda1
refind-install --usedefault /dev/sda1
umount /dev/sda1
mount /dev/sda1 /boot
cp /root/refind.conf /boot/EFI/BOOT/refind.conf
rm -f /root/postinstall.sh
rm -f /root/refind.conf
#findmnt /boot
#efibootmgr --create --disk /dev/sda --part 1 --loader /EFI/BOOT/refind_x64.efi --label "rEFInd Boot Manager" --verbose
