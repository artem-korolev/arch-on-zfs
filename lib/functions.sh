#!/usr/bin/env bash

function show_usage() {
    echo "Usage:"
    echo "install_gentoo_on_zfs [OPTION=VALUE] ..."
    echo
    echo "Options:"
    echo "  -n, --name:  machine name"
    echo "  -d, --disk:  absolute path to disk device (use by-id. Example, -d=/dev/disk/by-id/nvme-eui.0025385891502595)"
    echo "  -s, --swap:  swap filesystem size (Example: -s=64GB)"
    echo "               Default: ${DEFAULT_SWAPSIZE}"
    echo "  -h, --help:  show help"
}

function partiotion_all_disk_for_installation() {
    # to create the partitions programatically (rather than manually)
    # we're going to simulate the manual input to fdisk
    # The sed script strips off all the comments so that we can
    # document what we're doing in-line with the actual commands
    # Note that a blank line (commented as "defualt" will send a empty
    # line terminated with a newline to take the fdisk default.
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk ${DISK}
  o # clear the in memory partition table
  n # new partition
  p # primary partition
  1 # partition number 1
    # default - start at beginning of disk
  +512M # 512MB EFI Boot parttion
  n # new partition
  p # primary partition
  2 # partion number 2
    # default, start immediately after preceding partition
  +${SWAPSIZE}  # 50GB swap partiotion
  n # new partition
  p # primary partition
  3 # partion number 3
    # default, start immediately after preceding partition
  +2G  # 2GB ZFS bpool partiotion (Solaris boot)
  n # new partition
  p # primary partition
  4 # partion number 3
    # default, start immediately after preceding partition
    # take rest of space for ZFS rpool (Solaris root)
  t # change partiotion types
  1 # partition number 1
  1 # EFI Boot
  t # change partiotion types
  2 # partition number 1
  19 # Linux swap
  t # change partiotion types
  3 # partition number 1
  65 # Solaris boot
  t # change partiotion types
  4 # partition number 1
  66 # Solaris root
  p # print the in-memory partition table
  w # write the partition table
  q # and we're done
EOF
}