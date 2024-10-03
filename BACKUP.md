# Backup / Restore with rsync

Backup:

```bash
rsync -aAXv --delete --dry-run /home/ /path/to/backup/rsync/
rsync -aAX --delete /home/ /path/to/backup/rsync/
```

Restore:

```bash
rsync -aAXv --delete --dry-run /path/to/backup/rsync/ /home/
rsync -aAX --delete /path/to/backup/rsync/ /home/
```
