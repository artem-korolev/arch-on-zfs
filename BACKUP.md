# Backup / Restore with rsync

## Initializing drive for backups

```bash
zpool create -o ashift=12 -O compression=gzip-9 -O mountpoint=/backup backuppool /dev/sdX

...
zfs mount backuppool
zfs unmount backuppool
zpool import backuppool
zpool export backuppool
```

## Snapshot before backup

```bash
zfs snapshot backuppool@snapshot_name
```

## Backup

```bash
rsync -aAXv --delete --dry-run /home/ /path/to/backup/rsync/
rsync -aAX --delete /home/ /path/to/backup/rsync/
```

## Restore

```bash
rsync -aAXv --delete --dry-run /path/to/backup/rsync/ /home/
rsync -aAX --delete /path/to/backup/rsync/ /home/
```

## Check compress ratio of zfs backup pool/dataset

```bash
zfs get compressratio backuppool
```
