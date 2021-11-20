#!/usr/bin/env bash
source "lib/functions.sh"
source "lib/march.sh"

SUPPORTED_MARCHS=("native" "skylake" "haswell" "ivybridge" "sandybridge" "nehalem" "westmere"
"core2" "pentium-m" "nocona" "prescott" "znver1" "znver2" "znver3" "bdver4" "bdver3"
"btver2" "bdver2" "bdver1" "btver1" "amdfam10" "opteron-sse3" "geode" "opteron"
"power8")
DEFAULT_MICROARCHITECTURE="native"
DEFAULT_SWAPSIZE=40G
RPOOL=${RPOOL:=rpool}
BPOOL=${BPOOL:=bpool}
export RPOOL
export BPOOL
AUTHORIZED_KEY_FILE=
SWAPSIZE=

POSITIONAL=()
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -d|--disk)
            DISK="$2"
            shift # past argument
            shift # past value
        ;;
        -r|--root)
            ROOT_DISK_ON_TARGET_MACHINE="$2"
            shift # past argument
            shift # past value
        ;;
        -n|--name)
            MACHINENAME="$2"
            shift # past argument
            shift # past value
        ;;
        -s|--swap)
            SWAPSIZE="$2"
            shift # past argument
            shift # past value
        ;;
        -k|--key)
            AUTHORIZED_KEY_FILE="$2"
            shift # past argument
            shift # past value
        ;;
        -m|--march)
            MICROARCHITECTURE="$2"
            shift # past argument
            shift # past value
        ;;
        -h|--help)
            show_usage
            exit 0
        ;;
        *)
            echo "ERROR: Unknown option $i"
            echo
            show_usage
            exit 1
        ;;
    esac
done

## CHECK INPUT PARAMETERS
if [ -z "$DISK" ]; then
    show_usage
    exit 1
fi

if [ -z "$ROOT_DISK_ON_TARGET_MACHINE" ]; then
    ROOT_DISK_ON_TARGET_MACHINE="${DISK}"
fi
export ROOT_DISK_ON_TARGET_MACHINE

if [ -z "$MACHINENAME" ]; then
    show_usage
    exit 1
fi

if [ -z "$AUTHORIZED_KEY_FILE" ]; then
    echo "Error: path to ssh public key for root access is not specified"
    show_usage
    exit 1
fi

if [[ -z "${SWAPSIZE}" ]]; then
    SWAPSIZE=${DEFAULT_SWAPSIZE}
fi

if [[ ! "${SWAPSIZE}" =~ [0-9]+[K|M|G|T]$ ]]; then
    echo "Swapsize incorrectly specified: ${SWAPSIZE}"
    echo "Example: 512K, 512M, 32G, 1T"
    echo "Default: ${DEFAULT_SWAPSIZE}"
    exit 1
fi

if [[ -z "${MICROARCHITECTURE}" ]]; then
    MICROARCHITECTURE=${DEFAULT_MICROARCHITECTURE}
fi

if [[ "${MICROARCHITECTURE}" == "native" ]]; then
    echo "You choose to build with 'native' micro architecture."
    echo "Script is unable to automatically select kernel in that case."
    PS3="Select kernel:"
    select kernel in amd intel
    do
        TARGET_KERNEL=${kernel}
    done
else
    get_kernel_by_march "${MICROARCHITECTURE}"
fi

containsElement "${MICROARCHITECTURE}" "${SUPPORTED_MARCHS[@]}"
if [[ $? -eq 1 ]]; then
    echo "Error: Unsupported architecture: ${MICROARCHITECTURE}"
    echo "Supported architectures: ${SUPPORTED_MARCHS[@]}"
    exit 1
fi
export MICROARCHITECTURE

echo "DISK=${DISK} ROOT_DISK_ON_TARGET_MACHINE=${ROOT_DISK_ON_TARGET_MACHINE}"
echo "MACHINE_NAME=${MACHINENAME} SWAPSIZE=${SWAPSIZE}"

if [ ! -z $(readlink -e "/mnt/gentoo") ]; then
    echo "Error: Cannot proceed futher, because /mnt/gentoo directory already"
    echo "exist. If you had problems with installation, then you must carefully"
    echo "unmount all datasets and pools manually and remove /mnt/gentoo directory then."
    echo
    show_unmount_failure_warning
    exit 1
fi

## ATTENTION!!! DISK WRITE STARTS HERE
#PS3="WARNING!!!: ALL DATA ON THIS DEVICE WILL BE ERAZED!!! Are you sure you want to install system on ${DISK} block device? : "
#select continue_install in yes no
#do
        CONTINUE_INSTALL=${continue_install}
#done

#if [[ "${CONTINUE_INSTALL}" == "no" ]]; then
#    exit 0
#fi

## INITIALIZE DISK LAYOUT
source ./lib/partiotion_all_disk_for_installation.sh "${MACHINENAME}" "${DISK}" "${SWAPSIZE}" 1>/dev/null 2>&1
if [[ $? -eq 0 ]]; then
    echo "SUCCESS: disk layout for ZFS instalaltion is written to ${DISK}. Output of 'partprobe' command:"
    modprobe_disk "${DISK}"
else
    echo "Error: cannot create disk layout for ZFS installation. Output of 'partprobe' command:"
    modprobe_disk "${DISK}"
    exit 1
fi

# TODO: I have no idea why script fails to create FAT32 filysystem on newly partitioned disk.
#       It works good after restart. Issue occures when restarting installation several times.
sleep 5

cwd=$(pwd)

## UBUNTU
# apt update
# apt install -y curl

# ## umount and export all pools after failed installation
# umount /mnt/gentoo/boot/efi 1>/dev/null 2>&1 || true
# zfs umount /mnt/gentoo/boot 1>/dev/null 2>&1 || true
# umount /mnt/gentoo/boot 1>/dev/null 2>&1 || true
# umount -l /mnt/gentoo/{dev,sys,proc} 1>/dev/null 2>&1 || true
# zfs umount /mnt/gentoo 1>/dev/null 2>&1 || true
# umount -R /mnt/gentoo 1>/dev/null 2>&1 || true
# zpool export installation_bpool 1>/dev/null 2>&1 || true
# zpool export installation_rpool 1>/dev/null 2>&1 || true
#rm -Rf /mnt/gentoo

## FORMAT SWAP AND EFI Boot partiotions
mkfs.fat -F 32 -I "${DISK}-part1"
if [[ $? -eq 0 ]]; then
    echo "SUCCESS: EFI Boot partition is formatted as FAT32 on ${DISK}-part1"
else
    echo "Error: Cannot format ${DISK}-part1 as FAT32"
    exit 1
fi

mkswap "${DISK}-part2"

if [[ $? -eq 0 ]]; then
    echo "SUCCESS: ${DISK}-part2 parition is formatted as swap"
else
    echo "Error: Cannot format ${DISK}-part2 as swap"
    exit 1
fi

# CREATE MOUNT POINT FOR INSTALLATION ZFS POOLS
mkdir -p /mnt/gentoo


#zpool create \
#    -o ashift=12 \
#    -o cachefile=/etc/zfs/zpool.cache \
#    -O acltype=posixacl -O canmount=off -O compression=lz4 \
#    -O dnodesize=auto -O normalization=formD -O relatime=on \
#    -O xattr=sa -O mountpoint=/ -R /mnt/gentoo \
#    ${RPOOL} ${DISK}-part3

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
-t installation_${BPOOL}              \
${BPOOL} "${DISK}-part3"

if [[ $? -eq 0 ]]; then
    echo "SUCCESS: Created ZFS bpool on ${DISK}-part3"
else
    echo "Error: Cannot create ZFS bpool on ${DISK}-part3"
    exit 1
fi

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
-t installation_${RPOOL}              \
${RPOOL} "${DISK}-part4"

if [[ $? -eq 0 ]]; then
    echo "SUCCESS: Created ZFS rpool on ${DISK}-part4"
else
    echo "Error: Cannot create ZFS rpool on ${DISK}-part4"
    show_unmount_failure_warning
    exit 1
fi

### BOOT
zfs create -o canmount=off -o mountpoint=none installation_${BPOOL}/BOOT
zfs create -o canmount=noauto -o dnodesize=legacy -o mountpoint=/boot installation_${BPOOL}/BOOT/gentoo

### ROOT
zfs create -o canmount=off -o mountpoint=none installation_${RPOOL}/ROOT
zfs create -o canmount=noauto -o mountpoint=/ installation_${RPOOL}/ROOT/gentoo



zfs mount installation_${RPOOL}/ROOT/gentoo
zfs mount installation_${BPOOL}/BOOT/gentoo





zfs create                                 installation_${RPOOL}/home
zfs create -o mountpoint=/root             installation_${RPOOL}/home/root
chmod 700 /mnt/gentoo/root
zfs create -o canmount=off                 installation_${RPOOL}/var
zfs create -o canmount=off                 installation_${RPOOL}/var/lib
zfs create                                 installation_${RPOOL}/var/log
zfs create                                 installation_${RPOOL}/var/spool
zfs create -o com.sun:auto-snapshot=false  installation_${RPOOL}/var/cache
zfs create -o com.sun:auto-snapshot=false  installation_${RPOOL}/var/tmp
chmod 1777 /mnt/gentoo/var/tmp
zfs create                                 installation_${RPOOL}/opt
zfs create                                 installation_${RPOOL}/srv
zfs create -o canmount=off                 installation_${RPOOL}/usr
zfs create                                 installation_${RPOOL}/usr/local
zfs create                                 installation_${RPOOL}/var/games
# TODO: WARNING: net-mail/mailbase prevents mounting /var/mail as filesystem
# so if you want to claws-mail and its dependencies, then do not create
# /var/mail as separate filesystem
zfs create                                 installation_${RPOOL}/var/spool/mail
zfs create                                 installation_${RPOOL}/var/snap
zfs create                                 installation_${RPOOL}/var/www
zfs create                                 installation_${RPOOL}/var/lib/AccountsService
zfs create -o com.sun:auto-snapshot=false  installation_${RPOOL}/var/lib/docker
zfs create                                 installation_${RPOOL}/var/lib/flatpack
zfs create -o com.sun:auto-snapshot=false  installation_${RPOOL}/var/lib/nfs
zfs create -o com.sun:auto-snapshot=false -o compression=off -o relatime=off -o atime=off installation_${RPOOL}/chiatmp
zfs create -o com.sun:auto-snapshot=false -o relatime=off -o atime=off installation_${RPOOL}/tmp


cd /mnt/gentoo
latest_stage3=$(curl http://ftp.snt.utwente.nl/pub/os/linux/gentoo/releases/amd64/autobuilds/latest-stage3-amd64-systemd.txt 2>/dev/null | awk '$0 !~ /^#/ { print $1; exit; };')
wget http://distfiles.gentoo.org/releases/amd64/autobuilds/$latest_stage3
tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner
cd ${cwd}
mkdir /mnt/gentoo/root/.ssh/
if [ ! -z "${AUTHORIZED_KEY_FILE}"]; then
    cat ${AUTHORIZED_KEY_FILE} > /mnt/gentoo/root/.ssh/authorized_keys
fi
chmod -R go-rwx /mnt/gentoo/root/.ssh/
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
cp -R configs/systemd/* /etc/systemd/
## portage configs
cp -R configs/portage/* /mnt/gentoo/etc/portage/
MAKECONF_COMMON_FLAGS='${COMMON_FLAGS}'
export MAKECONF_COMMON_FLAGS
cat ./templates/make.conf | envsubst > /mnt/gentoo/etc/portage/make.conf
# cp /tmp/zpool.cache /mnt/gentoo/etc/zfs/
cp configs/locale.gen /mnt/gentoo/etc/locale.gen
cat ./templates/fstab | envsubst > /mnt/gentoo/etc/fstab
cp "configs/kernel/kconfig_${TARGET_KERNEL}" /mnt/gentoo/kconfig
cp configs/grub /mnt/gentoo/etc/default/grub


mkdir /mnt/gentoo/boot/efi
mount "${DISK}-part1" /mnt/gentoo/boot/efi


cp ./in_chroot.sh /mnt/gentoo
chroot /mnt/gentoo /in_chroot.sh
rm /mnt/gentoo/in_chroot.sh

umount /mnt/gentoo/boot/efi
if [[ $? -eq 0 ]]; then
    echo "SUCCESS: RPOOL datasets are successfully unmounted from /mnt/gentoo"
else
    echo "Error: Cannot unmount EFI Boot at /mnt/gentoo/boot/efi"
    show_unmount_failure_warning
    exit 1
fi
umount -l /mnt/gentoo/{dev,sys,proc}
if [[ $? -eq 0 ]]; then
    echo "SUCCESS: Virtual filesystems are unmounted from /mnt/gentoo/{dev,sys,proc}"
else
    echo "Error: Cannot unmount virtual filesystems, mounted at /mnt/gentoo/{dev,sys,proc}"
    show_unmount_failure_warning
    exit 1
fi
zfs umount /mnt/gentoo/boot
if [[ $? -eq 0 ]]; then
    echo "SUCCESS: BPOOL datasets are successfully unmounted from /mnt/gentoo/boot"
else
    echo "Error: Cannot unmount bpool datasets from /mnt/gentoo/boot"
    show_unmount_failure_warning
    exit 1
fi
zfs set mountpoint=legacy installation_${BPOOL}/BOOT/gentoo
if [[ $? -eq 0 ]]; then
    echo "SUCCESS: Set mountpoint for installation_${BPOOL}/BOOT/gentoo to 'legacy'"
else
    echo "Error: Cannot set mountpoint for installation_${BPOOL}/BOOT/gentoo to 'legacy'"
    show_unmount_failure_warning
    exit 1
fi

# UNMOUNT DATASETS FROM RPOOL pool
# TODO: find a way how to unmount dataset with all nested datasets
# using zfs utility, or unmount it one by one, if there is no other way
# Currently I decided to use 'umount -R ...', cause it just works.
# zfs umount /mnt/gentoo
RPOOL_MOUNTS=(
    "/mnt/gentoo/root"
    "/mnt/gentoo/home"
    "/mnt/gentoo/var/games"
    "/mnt/gentoo/var/tmp"
    "/mnt/gentoo/var/cache"
    "/mnt/gentoo/var/spool/mail"
    "/mnt/gentoo/var/spool"
    "/mnt/gentoo/var/lib/AccountsService"
    "/mnt/gentoo/var/lib/docker"
    "/mnt/gentoo/var/lib/nfs"
    "/mnt/gentoo/var/log"
    "/mnt/gentoo/var/snap"
    "/mnt/gentoo/var/www"
    "/mnt/gentoo/opt"
    "/mnt/gentoo/srv"
    "/mnt/gentoo/usr/local"
    "/mnt/gentoo/chiatmp"
    "/mnt/gentoo/tmp"
)
for i in "${RPOOL_MOUNTS[@]}"
do
    zfs unmount $i
    if [[ $? -eq 0 ]]; then
        echo "SUCCESS: Successfully unmounted ZFS dataset from $i"
    else
        echo "Error: Cannot unmount ZFS dataset from $i"
        show_unmount_failure_warning
        exit 1
    fi
done
zfs unmount /mnt/gentoo
if [[ $? -eq 0 ]]; then
    echo "SUCCESS: RPOOL datasets are successfully unmounted from /mnt/gentoo"
else
    echo "Error: Cannot unmount rpool datasets from /mnt/gentoo"
    show_unmount_failure_warning
    exit 1
fi
rm -R /mnt/gentoo
if [[ $? -eq 0 ]]; then
    echo "SUCCESS: /mnt/gentoo directory removed"
else
    echo "Error: Cannot remove /mnt/gentoo directory"
    show_unmount_failure_warning
    exit 1
fi

## FINALLY EXPORT ZFS POOLS
zpool export installation_${BPOOL}
if [[ $? -eq 0 ]]; then
    echo "SUCCESS: BPOOL is successfully exported"
else
    echo "Error: Cannot export BPOOL (installation_${BPOOL})"
    show_unmount_failure_warning
    exit 1
fi
zpool export installation_${RPOOL}
if [[ $? -eq 0 ]]; then
    echo "SUCCESS: RPOOL is successfully exported"
else
    echo "Error: Cannot	export RPOOL (installation_${RPOOL})"
    show_unmount_failure_warning
    exit 1
fi


echo "SUCCESS!!! ALL STEPS ARE SUCCESSFULLY COMPLETED."
echo "    If you installing Gentoo on this PC (from USB flash), then just restart."
echo "    If you install system on external drive using another computer, then"
echo "    disconnect your drive with newly installed system from computer."
echo "    Installation scripts creates pools with names '${RPOOL}' and '${BPOOL}'"
echo "    on specified block device. It can cause conflict with your running"
echo "    system after reboot, if your system is using ZFS pools with same names"
echo
echo "CONGRATS!!! One more installation of Gentoo Linux on ZFS!"
