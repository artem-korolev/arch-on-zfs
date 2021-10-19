#!/usr/bin/env bash

function show_usage() {
	echo "Usage:"
	echo "install_gentoo_on_zfs [OPTION=VALUE] ..."
	echo
	echo "Options:"
	echo "  -n <name>, --name <name>:  machine name"
	echo "  -d <block_device>, --disk <block_device>:  absolute path to disk device (use by-id. Example, -d=/dev/disk/by-id/nvme-eui.0025385891502595)"
	echo "  -s <size>, --swap <size>:  swap filesystem size in K/M/G/T (Example: -s=64G)"
	echo "               Default: ${DEFAULT_SWAPSIZE}"
	echo "  -k <path>, --key <path> : path to ssh public key (Gives SSH root access to the system)"
	echo "  -m <march>, --march <march> : build for specific architecture."
	echo "               Supported architectures: ${SUPPORTED_MARCHS[@]}"
	echo "               Default: ${DEFAULT_MICROARCHITECTURE}"
	echo "               Check more details here - https://wiki.gentoo.org/wiki/Safe_CFLAGS"
	echo "  -h, --help:  show help"
}

function show_unmount_failure_warning() {
	echo
	echo "WARNING!!!"
	echo "You may need manually unmound all zfs datasets, that belong to"
	echo "'installation_${RPOOL}' and 'installation_${BPOOL}' ZFS pools."
	echo "And after that you must export both of the installation pools."
	echo "Use 'zfs list | grep installation_' to get list of all datasets,"
	echo "that must be unmounted. And 'zpool list | grep installation_',"
	echo "to get list of pools, must to be exported."
	echo
	echo "zfs unmount <mount-point>"
	echo "zpool export <pool>"





# UNMOUNT LEGACY MOUNTPOONT - EFI Boot and virtual file systems
umount /mnt/gentoo/boot/efi || true

umount -l /mnt/gentoo/{dev,sys,proc}
if [[ $? -eq 0 ]]; then
    echo "SUCCESS: Virtual filesystems are unmounted from /mnt/gentoo/{dev,sys,proc}"
else
    echo "Error: Cannot unmount virtual filesystems, mounted at /mnt/gentoo/{dev,sys,proc}"
fi

# UNMOUNT DATASETS FROM RPOOL pool
# TODO: find a way how to unmount dataset with all nested datasets
# using zfs utility, or unmount it one by one, if there is no other way
# Currently I decided to use 'umount -R ...', cause it just works.
# zfs umount /mnt/gentoo
RPOOL_MOUNTS=(
    "/mnt/gentoo/boot"
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
    fi
done
zfs unmount /mnt/gentoo
if [[ $? -eq 0 ]]; then
    echo "SUCCESS: RPOOL datasets are successfully unmounted from /mnt/gentoo"
else
    echo "Error: Cannot unmount rpool datasets from /mnt/gentoo"
fi

if [ -d "/mnt/gentoo" ]; then
    rm /mnt/gentoo
    if [[ $? -eq 0 ]]; then
        echo "SUCCESS: /mnt/gentoo directory removed"
    else
        echo "Error: Cannot remove /mnt/gentoo directory, because its not empty."
        echo "Now you must manually care about rest of mounted ZFS datasets and pools"
        echo "Check mountpoint, if you have important files there, unmount and export"
        echo "ZFS datasets and pools starting with 'installation_' and remove /mnt/gentoo"
    fi
fi

## FINALLY EXPORT ZFS POOLS
zpool export installation_${BPOOL}
if [[ $? -eq 0 ]]; then
    echo "SUCCESS: BPOOL is successfully exported"
else
    echo "Error: Cannot export BPOOL (installation_${BPOOL})"
fi
zpool export installation_${RPOOL}
if [[ $? -eq 0 ]]; then
    echo "SUCCESS: RPOOL is successfully exported"
else
    echo "Error: Cannot export RPOOL (installation_${RPOOL})"
fi








}

function modprobe_disk() {
	part_probe_result=$(partprobe -d -s "${DISK}")
	echo "${part_probe_result}"
}

containsElement () {
	local e match="$1"
	shift
	for e; do [[ "$e" == "$match" ]] && return 0; done
	return 1
}
