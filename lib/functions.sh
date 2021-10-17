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