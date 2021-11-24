#!/usr/bin/env bash

MACHINE_NAME="$1"
BLOCK_DEVICE="$2"
SWAPFILE_SIZE="$3"

cat templates/disk.layout | sfdisk ${BLOCK_DEVICE}
