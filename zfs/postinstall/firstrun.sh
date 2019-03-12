#!/bin/bash

zpool set cachefile=/etc/zfs/zpool.cache zroot
systemctl enable zfs-import-cache
systemctl enable zfs-mount
systemctl enable zfs-import.target
zgenhostid $(hostid)
mkinitcpio -p linux
reboot
