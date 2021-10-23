# Install Gentoo on ZFS

:warning: WARNING

``Use it on your own risk!!! Script imports ZFS pools starting with
**'installation_...'** prefix into running system. Make sure you
do not have it already inside running environment.
Drive with installed system will have two ZFS pools:
**bpool** and **rpool**. If you have ZFS pools with same names,
you can get conflict during boot. So disconnect installation
target drive before boot.``

I created script to automate process of installing Gentoo on
ZFS file system.

It has configurations of portage packages, that I prefer personally.

It has also kernel configurations for two micro architectures: AMD and Intel.

## Requirements

- systemd on host machine (machine you run this script on)

   Script was designed to run in Linux using bash shell.
   It expects environment with **systemd**.

   If it's not **systemd**, then it most probably will install everything
   correctly.
   But there will be problems in "unmount stage". Script will fail to unmount
   **/mnt/gentoo/{dev,sys,proc}** virtual file systems, and will show you warning
   about it. Just follow suggested steps to manually unmount all datasets and
   export corresponding pools. That way you'll be able to manually finalize
   installation in non-systemd environment.

- AMD / Intel processor on target machine

- Disk with enough space to install Gentoo
  (minimal installation with ZFS modules)

## Usage

```bash
Usage:
install_gentoo_on_zfs [OPTION=VALUE] ...

Options:
  -n <name>, --name <name>:  machine name
  -d <block_device>, --disk <block_device>:  absolute path to disk
                   device (use by-id.
                   Example:
                   -d=/dev/disk/by-id/nvme-eui.0025385891502595)
  -r <root_device_on_target_machine>, --root <root_device_on_target_machine>:
                        root disk on target machine; this will be used to configure
                        /etc/fstab on target machine. By default equals
                        to value from **-d** option
  -s <size>, --swap <size>:  swap filesystem size in K/M/G/T (Example: -s=64G)
               Default: 40G
  -k <path>, --key <path> : path to ssh public key (Gives SSH root access to the system)
  -m <march>, --march <march> : build for specific architecture.
               Supported architectures: native skylake haswell ivybridge
               sandybridge nehalem westmere core2 pentium-m nocona prescott
               znver1 znver2 znver3 bdver4 bdver3 btver2 bdver2 bdver1
               btver1 amdfam10 opteron-sse3 geode opteron power8
               Default: native
               Check more details here - https://wiki.gentoo.org/wiki/Safe_CFLAGS
  -h, --help:  show help
```

## Examples

For example, run as root:

```bash
./install_gentoo_on_zfs.sh \
    -n intel10core \
    -d /dev/disk/by-id/<block-device> \
    -k <path-to-ssh-public-key>
    -m native
```

If you want more specific optimizations, or cross compiling for another
system:

### AMD Ryzen Zen3

I have AMD Zen3 processor, so I run it like that:

```bash
./install_gentoo_on_zfs.sh \
    -n intel10core \
    -d /dev/disk/by-id/<block-device> \
    -k <path-to-ssh-public-key>
    -m znver3
```

### INTEL Sky Lake / Comet Lake

I have AMD Zen3 processor, so I run it like that:

```bash
./install_gentoo_on_zfs.sh \
    -n intel10core \
    -d /dev/disk/by-id/<block-device> \
    -k <path-to-ssh-public-key>
    -m skylake
```

Refer to
[https://wiki.gentoo.org/wiki/Safe_CFLAGS](https://wiki.gentoo.org/wiki/Safe_CFLAGS)
for more details about available micro architectures and recommended compiler
flags.

For more specific cases, like ARM or very old/exotic architectures you most
probably need to adjust the script. There are two things to care of:

- **COMMON_FLAGS** in **templates/make.conf**

- kernel configuration in **configs/kernel**

Currently, automatic choice of kernel config and COMMON_FLAGS works only for
recent AMD and Intel processors.
And in any way you need to specify CPU micro architecture of target system
using **-m** option.

## What you get

Minimal system with OpenSSH will be installed. Public key specified with **-k**
option will be added to /root/authorized_keys. It will give you root SSH access
to the system using corresponding private key.

**/chiatmp** can be used for plotting Chia plots (it does not compress and
does not log access to file system).
[https://www.chia.net/](https://www.chia.net/)

## To-do

- adjust script to run in non-systemd environments

- make processor detection and auto selection of micro architecture

- select proper COMMON_FLAGS and kernel config for selected architecture
(**-m**)

- download stage3 archive from nearest mirror

## Contributors

Open issue, if you have any question.

Fork and make pull request, if you want to contribute.
