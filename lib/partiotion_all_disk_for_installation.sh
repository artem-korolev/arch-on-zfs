#!/usr/bin/env bash

MACHINE_NAME="$1"
BLOCK_DEVICE="$2"
SWAPFILE_SIZE="$3"

cat templates/disk.layout | sfdisk ${BLOCK_DEVICE}
exit 0


# to create the partitions programatically (rather than manually)
# we're going to simulate the manual input to fdisk
# The sed script strips off all the comments so that we can
# document what we're doing in-line with the actual commands
# Note that a blank line (commented as "defualt" will send a empty
# line terminated with a newline to take the fdisk default.
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk ${BLOCK_DEVICE} 2>&1
  g # clear the in memory partition table
  n # new partition
  p # primary partition
  1 # partition number 1
    # default - start at beginning of disk
  +512M # 512MB EFI Boot parttion
  n # new partition
  p # primary partition
  2 # partion number 2
    # default, start immediately after preceding partition
  +${SWAPFILE_SIZE}  # 50GB swap partiotion
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
