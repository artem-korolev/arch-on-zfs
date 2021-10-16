#!/usr/bin/env bash

function show_usage() {
echo "Usage:"
	echo "install_gentoo_on_zfs [OPTION=VALUE] ..."
	echo
	echo "Options:"
	echo "  -n, --name:  machine name"
	echo "  -d, --disk:  absolute path to disk device (use by-id. Example, -d=/dev/disk/by-id/nvme-eui.0025385891502595)"
	echo "  -s, --swap:  swap filesystem size in K/M/G/T (Example: -s=64G)"
	echo "               Default: ${DEFAULT_SWAPSIZE}"
	echo "  -h, --help:  show help"
}

function modprobe_disk() {
	part_probe_result=$(partprobe -d -s "${DISK}")
	echo "${part_probe_result}"
}
