#!/bin/bash

HDD=/dev/sda

dhclient
loadkeys us
timedatectl set-ntp true

modprobe zfs

echo "partitioning"
parted --script ${HDD} mklabel gpt mkpart primary 0% 200M mkpart primary 200M 100% set 1 boot on set 1 esp on
partprobe
echo "format esp (efi boot) partition to fat32"
mkfs.fat -F32 ${HDD}1
modprobe zfs
echo "create zpool"
zpool create -f -o ashift=12 -m /zroot zroot /dev/disk/by-id/ata-VBOX_HARDDISK_VB09aeb64a-c95d6fd9-part2
# create swap for target system
echo "creating swap"
zfs create -V 32G -b $(getconf PAGESIZE) -o logbias=throughput -o sync=always -o primarycache=metadata -o com.sun:auto-snapshot=false zroot/archlinux-swap
zfs create -V 34G -b $(getconf PAGESIZE) -o logbias=throughput -o sync=always -o primarycache=metadata -o com.sun:auto-snapshot=false zroot/archlinux-hibernate


echo "creating sys/data datasets"
# create sys and data datasets
zfs set atime=on zroot
zfs set relatime=on zroot
zfs create -o mountpoint=none -p zroot/sys/archlinux
zfs create -o mountpoint=none zroot/data
zfs create -o mountpoint=none zroot/sys/archlinux/ROOT

echo "creating arch linux system datasets"
# creating system datasets
# /
zfs create -o compression=lz4 -o mountpoint=/ zroot/sys/archlinux/ROOT/default
# /boot
#zfs create -o compression=off -o mountpoint=/boot zroot/sys/archlinux/boot
# /etc
zfs create -o compression=gzip-9 -o mountpoint=/etc zroot/sys/archlinux/etc
# /home
zfs create -o compression=lz4 -o mountpoint=/home zroot/sys/archlinux/home
# /repos
zfs create -o compression=lz4 -o mountpoint=/repos zroot/data/repos
# /usr
zfs create -o compression=lz4 -o mountpoint=/usr zroot/sys/archlinux/usr
# /usr/local
zfs create -o compression=lz4 -o mountpoint=/usr/local zroot/sys/archlinux/usr/local
# /opt
zfs create -o compression=lz4 -o mountpoint=/opt zroot/sys/archlinux/opt
# /var
zfs create -o compression=off -o xattr=sa -o mountpoint=/var zroot/sys/archlinux/var
# /var/log
zfs create -o compression=lz4 -o xattr=sa -o mountpoint=/var/log zroot/sys/archlinux/var/log
# /var/log/journal
zfs create -o compression=off -o xattr=sa -o acltype=posixacl -o mountpoint=/var/log/journal zroot/sys/archlinux/var/log/journal
# /var/cache
zfs create -o compression=lz4 -o xattr=sa -o mountpoint=/var/cache zroot/sys/archlinux/var/cache
# /var/lib
zfs create -o compression=lz4 -o xattr=sa -o mountpoint=/var/lib zroot/sys/archlinux/var/lib
# /var/lib/docker
zfs create -o compression=lz4 -o xattr=sa -o mountpoint=/var/lib/docker zroot/sys/archlinux/var/lib/docker
# /var/spool
zfs create -o compression=lz4 -o xattr=sa -o mountpoint=/var/spool zroot/sys/archlinux/var/spool
# /var/spool/mail
zfs create -o compression=lz4 -o xattr=sa -o mountpoint=/var/spool/mail zroot/sys/archlinux/var/spool/mail

echo "mark boot dataset"
zpool set bootfs=zroot/sys/archlinux/ROOT/default zroot
echo "export zroot"
zpool export zroot
echo "import zroot"
zpool import -d /dev/disk/by-id -R /mnt zroot
zpool set cachefile=/etc/zfs/zpool.cache zroot
mkdir -p /mnt/etc/zfs/
cp /etc/zfs/zpool.cache /mnt/etc/zfs/zpool.cache
mkdir /mnt/boot
mount ${HDD}1 /mnt/boot
genfstab -U -p /mnt | grep "/boot" >> /mnt/etc/fstab
locale-gen en_US en_US.UTF-8
pacstrap /mnt base zfs-linux git base-devel refind-efi parted dhclient
cp ./installer/zfs/install/postinstall.sh /mnt/root/
cp ./installer/zfs/install/refind.conf /mnt/root/
cp -R ./installer/zfs/postinstall /mnt/root/
chmod a+x /mnt/root/postinstall.sh
arch-chroot /mnt /root/postinstall.sh
umount /mnt/boot
zfs umount -a
zpool export zroot
