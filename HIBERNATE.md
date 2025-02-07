# Hibernate

Linux have quite bad hibernate support. It has many issue. I write this
document to address one of them.

## Failure to allocate memory

It does not matter how large is your swap. It may fail even when swap has
enough free space in swap. Guess why??? ... Yep - fragmentation. It seems
it tries to allocate contiguous space in swap.

So. Very sad, Right? 2025 already on the street, but Linux still has so
poor hibernation support. I'm writing document, because I really want
my Linux system to be reliable same as modern Windows or MacOSX.

## Disclaimer

Unfortunately the nature of Linux swapping and hibernation does not give us
ability to be 100% safe here. So there is potential. So whatever you do,
however you implement your hibernation process, still there is a chance your
hibernate will fail.

## Let's start

My strategy is quite simple. Instead of using one big swap partition, I create
two partitions: first for swap - mounted automatically, second for hibernate
process.

And I do not use KDE/GNOME/UPower to hibernate. I create a custom hibernate
service. It monitors battery level, and when level is critical, then it
executes swapon for hibernate process and immediately forcing system to
hibernate (with force flags and ignoring inhibitors). Yes, there is a chance
here, that Linux kernel will immediately start using this new swap, but
probability here is quite small. And anyways, when you create your separate
hibernate partition, make it initially larger, then its needed. For example,
if you have 32GB RAM, make hibernate to be 33/34 GB. More space you reserve,
less probability it will fail to hibernate.

### Command to initialize swap and hibernate

Swap:

```bash
cryptsetup luksFormat /dev/disk/by-partuuid/<swap-partuuid>

cryptsetup open /dev/disk/by-partuuid/<swap-partuuid> cryptswap

mkswap -L swap /dev/mapper/cryptswap

swapon /dev/mapper/cryptswap
```

Hibernate:

```bash
cryptsetup luksFormat /dev/disk/by-partuuid/<hibernate-partuuid>

cryptsetup open /dev/disk/by-partuuid/<hibernate-partuuid> crypthibernate

mkswap -L swap /dev/mapper/crypthibernate
```

Edit **_/etc/crypttab_**:

```plain
cryptswap PARTUUID=<swap-partuuid> none luks,swap
crypthibernate PARTUUID=<hibernate-partuuid> none luks,swap
```

Make sure **_/etc/fstab_** contains proper entry also. Do not include hibernate
partition there:

```plain
...
/dev/mapper/cryptswap none swap sw 0 0
...
```

**_mkswap_** command will give you UUID of your new hibernate partition (don't
mix it with partuuid).

Edit **_/etc/initramfs-tools/conf.d/resume_**:

```plain
RESUME=UUID=<hibernate-uuid>
```

Edit **_/etc/default/grub_**. Your CMDLINE should look something like this:

```plain
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash resume=UUID=<hibernate-uuid> no_console_suspend"
```

Finally update initramfs and grub:

```bash
update-initramfs -u
update-grub
```

Ignore warning message, that **_update-initramfs_** will write about that
partition with some UUID is missing. If this UUID is not yours, then no
problems. Somehow it remembers last UUID and complaining, that cannot find it.
Also strange, but whatever.

Reboot.

Now you can test your new fancy hibernation process:

```bash
swapon "/dev/mapper/crypthibernate"
systemctl hibernate --force --ignore-inhibitors
swapoff "/dev/mapper/crypthibernate"
```

## Automated script example

I will not write here how to register SystemD timer. Check
**_playbooks/configure_power_management.yml_** Ansible playbook for details.

But for those, who want to use it in their custom setups I share example of
critical power monitoring and hibernate script:

```bash
#!/usr/bin/env bash
# Locate the battery device (assumes only one battery)
BATTERY_DEVICE=$(upower -e | grep -m 1 BAT)

# If no battery device is found, exit.
if [ -z "$BATTERY_DEVICE" ]; then
    exit 0
fi

# Check the battery state; only proceed if discharging.
BATTERY_STATE=$(upower -i "$BATTERY_DEVICE" | grep -m 1 'state:' | awk '{print $2}')
if [ "$BATTERY_STATE" != "discharging" ]; then
    # System is plugged in or fully charged – do nothing.
    exit 0
fi

# Get battery percentage
BATTERY_LEVEL=$(upower -i "$BATTERY_DEVICE" | grep percentage | awk '{print $2}' | sed 's/%//')
CRITICAL_THRESHOLD=8

if [ "$BATTERY_LEVEL" -le "$CRITICAL_THRESHOLD" ]; then
    swapon "/dev/mapper/crypthibernate"
    systemctl hibernate --force --ignore-inhibitors
    swapoff "/dev/mapper/crypthibernate"
fi
```

For script to work you need **_upower_** to be installed in you system. But
make sure to disable **_upower_** service and stop it, so processes do not
clash with its functionalities. Be free to implement battery checking with
something else, what you like more.

Ubuntu:

```bash
apt install upower
systemctl disable upower
systemctl disable upower
```

## To be fully safe

"Fully safe" means to at least sync your disks and shutdown properly.

I configure my KDE (or whatever desktop environment I use), to shutdown on
battery critical power level. For example, if my script hibernates, when
battery level is 8%, then I configure KDE to shutdown, when battery is 4%.

## Do not forget about BIOS settings

Of course you configure your laptop to go in Sleep mode, when lid is closed.
But laptop battery will get uncharged at some point. For this you need to
configure BIOS to wake up from sleep on critical power level.

It will make sure your system runs your custom hibernate script

## Congratulations

Have and happy and safe **HIBERNATION** !!!

🤘💪🤣😍❤
