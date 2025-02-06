#!/usr/bin/env bash

# Usage: ./install-nixos.sh /dev/disk/by-id/xxxx [parameters,...]

# Ensure we have exactly one argument
if [ $# -lt 1 ]; then
  echo "Usage: $0 /dev/disk/by-id/<disk-id> [parameters,...]"
  echo "IMPORTANT!!!: Use disk by-id. Other options are not working"
  echo "Parameters:"
  echo "           --swap-size <N> - swap size in GiB"
  exit 1
fi

DISK="$1"
shift  # Remove the disk argument from the list

# Check the argument starts with /dev/disk/by-id/
if [[ "$DISK" != /dev/disk/by-id/* ]]; then
  echo "Error: Please specify the disk by ID, e.g. /dev/disk/by-id/xxx"
  exit 1
fi

echo "Using disk: $DISK"

# Parse arguments
SWAPSIZE=16
while [[ $# -gt 0 ]]; do
  case "$1" in
    --swap-size)
      shift
      if [[ -z "$1" ]]; then
        echo "Error: --swap-size requires a numeric argument."
        exit 1
      fi
      SWAPSIZE="$1"
      shift
      ;;
    *)
      # Unrecognized argument; handle as needed or break
      echo "Unrecognized argument: $1"
      exit 1
      ;;
  esac
done

echo "SWAPSIZE is set to: $SWAPSIZE"

# Read total memory (in kB) from /proc/meminfo
MEM_KB=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
# Convert to GB (rounding up). 1 GB = 1048576 kB.
MEM_GB=$(( (MEM_KB + 1048576 - 1) / 1048576 ))
MNT=$(mktemp -d)
HIBERNATESIZE=$(( MEM_GB + SWAPSIZE + 1 ))
RESERVE=1

set -euo pipefail

EFI_PART="${DISK}-part1"
export SWAP_PART="${DISK}-part2"
export HIBERNATE_PART="${DISK}-part3"
export RPOOL_PART="${DISK}-part4"
export ZFS_HOSTID=$(head -c 8 /etc/machine-id)

echo "Enter a single passphrase for all LUKS2 partitions:"
# -s makes 'read' silent (no echoing)
read -s ALL_LUKS_PASS


partition_disk () {
  local disk="$1"

  # Optional: discard the disk to remove any existing data
  blkdiscard -f "${disk}" || true

  # Calculate start/end points in GiB. The parted command interprets negative
  # offsets (e.g. -4GiB) as “4 GiB before the end of the disk.”

  # 1. EFI: from 1MiB to 1GiB
  local efiStart="1MiB"
  local efiEnd="1GiB"

  # 2. Swap: from 1GiB to (1 + SWAPSIZE) GiB
  local swapStart="1GiB"
  local swapEnd="$(( 1 + SWAPSIZE ))GiB"

  # 3. Hibernate: from swapEnd to (swapEnd + HIBERNATESIZE) GiB
  local hibernateStart="${swapEnd}"
  local hibernateEnd="$(( 1 + SWAPSIZE + HIBERNATESIZE ))GiB"

  # 4. rpool: from hibernateEnd to -RESERVE GiB from the disk’s end
  local rpoolStart="${hibernateEnd}"
  local rpoolEnd="-$(( RESERVE ))GiB"

  # Show summary
  echo "----------------------------------------"
  echo "Partition layout will be created on: ${disk}"
  echo "  1) EFI Partition   : from ${efiStart} to ${efiEnd} (ESP)"
  echo "  2) Swap Partition  : from ${swapStart} to ${swapEnd}"
  echo "  3) Hibernate Part. : from ${hibernateStart} to ${hibernateEnd}"
  echo "  4) rpool Partition : from ${rpoolStart} to ${rpoolEnd}"
  echo "----------------------------------------"

  read -r -p "Are you sure you want to proceed? Type 'yes' to continue: " confirm
  if [[ "${confirm}" != "yes" ]]; then
    echo "Aborting disk partitioning."
    exit 1
  fi

  # Create the GPT layout with parted
  parted --script --align=optimal "${disk}" -- \
    mklabel gpt \
    mkpart EFI "${efiStart}" "${efiEnd}" \
    set 1 esp on \
    mkpart swap "${swapStart}" "${swapEnd}" \
    mkpart hibernate "${hibernateStart}" "${hibernateEnd}" \
    mkpart rpool "${rpoolStart}" "${rpoolEnd}"

  # Update kernel partition info
  partprobe "${disk}"

  echo "Partitioning complete."
}


# Helper function to format and open a LUKS partition
#   $1 = device path (e.g. /dev/nvme0n1p2)
#   $2 = mapper name (e.g. cryptswap)
format_and_open_luks() {
  local dev="$1"
  local mapper_name="$2"

  echo "Formatting LUKS partition at: $dev"
  # Pass the stored passphrase via STDIN using --key-file=-
  # cryptsetup reads it from the pipe ("-d -").
  # --force-password ensures cryptsetup uses only one pass from STDIN.
  echo -n "$ALL_LUKS_PASS" | cryptsetup luksFormat --type luks2 "$dev" -d -

  echo "Opening LUKS partition -> /dev/mapper/$mapper_name"
  echo -n "$ALL_LUKS_PASS" | cryptsetup luksOpen "$dev" "$mapper_name" -d -
}

##################
#  GPT LAYOUT
##################
partition_disk "${DISK}"

##################
#  Swap Partition
##################
format_and_open_luks "${SWAP_PART}" "cryptswap"
# Create and enable the swap
mkswap /dev/mapper/cryptswap
swapon /dev/mapper/cryptswap

######################
# Hibernate Partition
######################
format_and_open_luks "${HIBERNATE_PART}" "crypthibernate"
# Create and enable the hibernate swap area
mkswap /dev/mapper/crypthibernate
swapon /dev/mapper/crypthibernate

###################
# Root Pool (ZFS)
###################
format_and_open_luks "${RPOOL_PART}" "cryptrpool"
# Now you can create your ZFS pool on /dev/mapper/cryptrpool, for example:
# zpool create -f -O mountpoint=none rpool /dev/mapper/cryptrpool
# ... and proceed with your ZFS layout commands.

echo "All LUKS partitions have been formatted and opened."


# 4. Create root pool
# shellcheck disable=SC2046
zpool create \
    -o ashift=12 \
    -o autotrim=on \
    -R "${MNT}" \
    -O acltype=posixacl \
    -O canmount=off \
    -O dnodesize=auto \
    -O normalization=formD \
    -O relatime=on \
    -O xattr=sa \
    -O mountpoint=none \
    rpool \
    /dev/mapper/cryptrpool

# 5. Create root system container:
zfs create -o canmount=noauto -o mountpoint=legacy rpool/root
zfs create -o mountpoint=legacy rpool/home
mount -o X-mount.mkdir -t zfs rpool/root "${MNT}"
mount -o X-mount.mkdir -t zfs rpool/home "${MNT}"/home


mkfs.vfat -n EFI "${EFI_PART}"
mount -t vfat -o fmask=0077,dmask=0077,iocharset=iso8859-1,X-mount.mkdir "${EFI_PART}" "${MNT}"/boot
nixos-generate-config --root "${MNT}"
envsubst < configuration.nix.template > "${MNT}/etc/nixos/configuration.nix"
nixos-install  --root "${MNT}"
cd
umount -Rl "${MNT}"
zpool export -a
