#!/usr/bin/env bash

cwd=$(pwd)

apt update
apt install -y curl

mkdir /mnt/gentoo

DISK=/dev/disk/by-id/nvme-eui.0025385891502595
mkfs.fat -F 32 ${DISK}-part1
mkswap ${DISK}-part2


#zpool create \
#    -o ashift=12 \
#    -o cachefile=/etc/zfs/zpool.cache \
#    -O acltype=posixacl -O canmount=off -O compression=lz4 \
#    -O dnodesize=auto -O normalization=formD -O relatime=on \
#    -O xattr=sa -O mountpoint=/ -R /mnt/gentoo \
#    rpool ${DISK}-part3

# * Messages for package sys-fs/zfs-kmod-2.0.4-r1:
#
# * This version of OpenZFS includes support for new feature flags
# * that are incompatible with previous versions. GRUB2 support for
# * /boot with the new feature flags is not yet available.
# * Do *NOT* upgrade root pools to use the new feature flags.
# * Any new pools will be created with the new feature flags by default
# * and will not be compatible with older versions of ZFSOnLinux. To
# * create a newpool that is backward compatible wih GRUB2, use 
# * 
# * zpool create -d -o feature@async_destroy=enabled 
# * 	-o feature@empty_bpobj=enabled -o feature@lz4_compress=enabled
# * 	-o feature@spacemap_histogram=enabled
# * 	-o feature@enabled_txg=enabled 
# * 	-o feature@extensible_dataset=enabled -o feature@bookmarks=enabled
# * 	...
# * 
# * GRUB2 support will be updated as soon as either the GRUB2
# * developers do a tag or the Gentoo developers find time to backport
# * support from GRUB2 HEAD.
    
    
## BPOOL - boot pool
zpool create -d -o feature@allocation_classes=enabled \
                      -o feature@async_destroy=enabled      \
                      -o feature@bookmarks=enabled          \
                      -o feature@embedded_data=enabled      \
                      -o feature@empty_bpobj=enabled        \
                      -o feature@enabled_txg=enabled        \
                      -o feature@extensible_dataset=enabled \
                      -o feature@filesystem_limits=enabled  \
                      -o feature@hole_birth=enabled         \
                      -o feature@large_blocks=enabled       \
                      -o feature@lz4_compress=enabled       \
                      -o feature@project_quota=enabled      \
                      -o feature@resilver_defer=enabled     \
                      -o feature@spacemap_histogram=enabled \
                      -o feature@spacemap_v2=enabled        \
                      -o feature@userobj_accounting=enabled \
                      -o feature@zpool_checkpoint=enabled   \
                      -f -o ashift=12                       \
                      -o autotrim=on                        \
                      -o cachefile=/tmp/zpool.cache         \
                      -O aclinherit=passthrough             \
                      -O acltype=posixacl                   \
                      -O atime=off                          \
                      -O canmount=off                       \
                      -O devices=off                        \
                      -O mountpoint=/                       \
                      -O normalization=formD                \
                      -O xattr=sa                           \
                      -R /mnt/gentoo                        \
                      bpool ${DISK}-part3
## RPOOL - root pool
zpool create -f -o ashift=12 \
                      -o autotrim=on                        \
                      -o cachefile=/tmp/zpool.cache         \
                      -O acltype=posixacl                   \
                      -O aclinherit=passthrough             \
                      -O atime=off                          \
                      -O canmount=off                       \
                      -O devices=off                        \
                      -O dnodesize=auto                     \
                      -O compression=lz4                    \
                      -O mountpoint=/                       \
                      -O normalization=formD                \
                      -O xattr=sa                           \
                      -R /mnt/gentoo                        \
                      rpool ${DISK}-part4


### BOOT
zfs create -o canmount=off -o mountpoint=none bpool/BOOT
zfs create -o canmount=noauto -o dnodesize=legacy -o mountpoint=/boot bpool/BOOT/gentoo

### ROOT
zfs create -o canmount=off -o mountpoint=none rpool/ROOT
zfs create -o canmount=noauto -o mountpoint=/ rpool/ROOT/gentoo



zfs mount rpool/ROOT/gentoo
zfs mount bpool/BOOT/gentoo





zfs create                                 rpool/home
zfs create -o mountpoint=/root             rpool/home/root
chmod 700 /mnt/gentoo/root
zfs create -o canmount=off                 rpool/var
zfs create -o canmount=off                 rpool/var/lib
zfs create                                 rpool/var/log
zfs create                                 rpool/var/spool
zfs create -o com.sun:auto-snapshot=false  rpool/var/cache
zfs create -o com.sun:auto-snapshot=false  rpool/var/tmp
chmod 1777 /mnt/gentoo/var/tmp
zfs create                                 rpool/opt
zfs create                                 rpool/srv
zfs create -o canmount=off                 rpool/usr
zfs create                                 rpool/usr/local
zfs create                                 rpool/var/games
zfs create                                 rpool/var/mail
zfs create                                 rpool/var/snap
zfs create                                 rpool/var/www
zfs create                                 rpool/var/lib/AccountsService
zfs create -o com.sun:auto-snapshot=false  rpool/var/lib/docker
zfs create -o com.sun:auto-snapshot=false  rpool/var/lib/nfs
zfs create -o com.sun:auto-snapshot=false -o compression=off -o relatime=off -o atime=off rpool/chiatmp
zfs create -o com.sun:auto-snapshot=false -o relatime=off -o atime=off rpool/tmp


cd /mnt/gentoo
latest_stage3=$(curl http://distfiles.gentoo.org/releases/amd64/autobuilds/latest-stage3-amd64-systemd.txt 2>/dev/null | awk '$0 !~ /^#/ { print $1; exit; };')
wget http://distfiles.gentoo.org/releases/amd64/autobuilds/$latest_stage3
tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner
cd ${cwd}
cp configs/make.conf /mnt/gentoo/etc/portage/make.conf
mkdir --parents /mnt/gentoo/etc/portage/repos.conf
cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev
test -L /dev/shm && rm /dev/shm && mkdir /dev/shm
mount --types tmpfs --options nosuid,nodev,noexec shm /dev/shm
chmod 1777 /dev/shm

mkdir /mnt/gentoo/etc/zfs
cp /tmp/zpool.cache /mnt/gentoo/etc/zfs/
cp configs/locale.gen /mnt/gentoo/etc/locale.gen
cp configs/fstab /mnt/gentoo/etc/
cp configs/kernel/.config /mnt/gentoo/
cp configs/grub /mnt/gentoo/

mkdir /mnt/gentoo/boot/efi
mount ${DISK}-part1 /mnt/gentoo/boot/efi


cp ./in_chroot.sh /mnt/gentoo
chroot /mnt/gentoo /in_chroot.sh


umount /mnt/gentoo/boot/efi
umount -l /mnt/gentoo/{dev,sys,proc}
zfs umount -a
zpool export -a


