#!/usr/bin/env bash

source /etc/profile
export PS1="(chroot) ${PS1}"

emerge --sync
if [[ $? -eq 0 ]]; then
    echo "SUCCESS: 'emerge --sync' done."
else
    echo "Error: 'emerge --sync' failed."
    exit 1
fi
emerge -v app-portage/gentoolkit
if [[ $? -eq 0 ]]; then
    echo "SUCCESS: 'emerge -v app-portage/gentoolkit' done."
else
    echo "Error: 'emerge -v app-portage/gentoolkit' failed."
    exit 1
fi
emerge -v app-portage/mirrorselect
if [[ $? -eq 0 ]]; then
    echo "SUCCESS: 'emerge -v app-portage/mirrorselect' done."
else
    echo "Error: 'emerge -v app-portage/mirrorselect' failed."
    exit 1
fi
emerge -v sys-fs/dosfstools
if [[ $? -eq 0 ]]; then
    echo "SUCCESS: 'emerge -v sys-fs/dosfstools' done."
else
    echo "Error: 'emerge -v sys-fs/dosfstools' failed."
    exit 1
fi
emerge -v net-misc/dhcpcd
if [[ $? -eq 0 ]]; then
    echo "SUCCESS: 'emerge -v net-misc/dhcpcd' done."
else
    echo "Error: 'emerge -v net-misc/dhcpcd' failed."
    exit 1
fi
mirrorselect -s4 -b10 -D
if [[ $? -eq 0 ]]; then
    echo "SUCCESS: 'mirrorselect -s4 -b10 -D' done."
else
    echo "Error: 'mirrorselect -s4 -b10 -D' failed."
    exit 1
fi

## nano -w /etc/locale.gen
locale-gen
eselect locale list
eselect locale set en_US.utf8
env-update && source /etc/profile && export PS1="(chroot) ${PS1}"
emerge --verbose --update --deep --newuse @world
ln -sf ../usr/share/zoneinfo/Europe/Tallinn /etc/localtime
env-update && source /etc/profile && export PS1="(chroot) ${PS1}"

cp -R /etc/portage.new/* /etc/portage/
rm -Rf /etc/portage.new
#emerge -vuDN @world

#mkdir /etc/portage/package.accept_keywords
#echo "sys-fs/zfs ~amd64" >> /etc/portage/package.accept_keywords/zfs
#echo "sys-fs/zfs-kmod ~amd64" >> /etc/portage/package.accept_keywords/zfs-kmod
#echo "sys-boot/grub ~amd64" >> /etc/portage/package.accept_keywords/grub
#echo "sys-boot/grub libzfs" > /etc/portage/package.use/grub


# kernel
#echo 'sys-kernel/linux-firmware @BINARY-REDISTRIBUTABLE' >> /etc/portage/package.license
emerge -uvDN sys-kernel/gentoo-sources:5.14.13 sys-kernel/genkernel
if [[ $? -eq 0 ]]; then
    echo "SUCCESS: 'emerge -uvDN sys-kernel/gentoo-sources-5.14.13 sys-kernel/genkernel' done."
else
    echo "Error: 'emerge -uvDN sys-kernel/gentoo-sources-5.14.13 sys-kernel/genkernel' failed."
    exit 1
fi
eselect kernel list
eselect kernel set 1
ls -l /usr/src/linux
emerge -v sys-apps/pciutils
cd /usr/src/linux
mv /kconfig ./.config
make olddefconfig
make && make modules_install
make install


# # soft
# emerge dev-vcs/git
# #echo 'sys-kernel/linux-firmware @BINARY-REDISTRIBUTABLE' >> /etc/portage/package.license
# #echo 'virtual/linux-sources firmware' >> /etc/portage/package.use/kernel
# #emerge --ask sys-kernel/linux-firmware
emerge -v zfs
emerge -v grub:2
emerge -v sys-fs/ntfs3g
emerge -v sys-process/lsof
# emerge -v dev-util/nvidia-cuda-toolkit
# emerge -v python
# emerge -v python:3.8
# emerge -v app-shells/bash-completion
# emerge -v x11-wm/i3
# emerge -v polybar
# emerge -v x11-misc/picom
# emerge -v htop
# emerge -v dmenu
# emerge -v usbutils
# emerge -v inotify-tools
# emerge -v vscode
# emerge -v sudo
# emerge -v wcalc speedcrunch
# emerge -v xfontsel
# emerge -v media-fonts/liberation-fonts media-fonts/noto media-fonts/paratype
# emerge -v qbittorrent
# emerge -v gimp
# paperconfig -p letter

# emerge -v media-sound/pavucontrol media-sound/pulsemixer media-sound/paprefs media-sound/pulseaudio-modules-bt i3 openbox xorg-x11 twm xterm xclock
# emerge -v app-emulation/docker
# emerge -v x11-terms/kitty terminus-font zsh zsh-completions
# emerge -v vim
# emerge -v powerline-symbols
# emerge -v media-fonts/source-code-pro media-fonts/fira-code
# emerge -v virtual/jdk
# emerge -v net-print/cups
# emerge -v --noreplace net-wireless/bluez
# emerge -v media-video/guvcview
# emerge -v media-video/obs-studio
# LDFLAGS_amd64="" emerge -v media-video/v4l2loopback
# emerge -v virtual/imagemagick-tools
# emerge -v sys-apps/etckeeper
# emerge -v sys-apps/dmidecode
# emerge -v dev-java/openjdk
# emerge -v dev-java/maven-bin
# emerge -v kde-apps/umbrello
# emerge -v app-office/dia
# emerge -v app-office/dia2code
# emerge -v app-emulation/docker app-emulation/docker-compose
# emerge -v net-im/telegram-desktop
# emerge -v app-crypt/gorilla
# emerge -v app-arch/p7zip
# emerge -v www-client/chromium
# emerge -v mail-client/kube mail-client/thunderbird mail-client/evolution mail-client/claws-mail
# emerge -v net-dns/bind-tools
# emerge -v dev-vcs/mr

# # Antivirus
# emerge -v app-antivirus/clamav
# emerge -v app-antivirus/clamtk

# # Flatpack
# emerge -v sys-apps/flatpak

# # Screenshot apps
# emerge -v media-gfx/scrot
# emerge -v x11-misc/shutter

# # PHP
# dev-lang/php

# # ASCII GENERATORS
# emerge -v app-misc/figlet
# emerge -v app-misc/toilet
# emerge -v games-misc/cowsay
# emerge -v app-misc/jq
# emerge -v media-sound/lilypond media-gfx/imagemagick dev-texlive/texlive-latex app-text/dvipng app-text/dvisvgm

# # IDEA
# emerge -v sys-libs/gdbm
# emerge -v dev-util/idea-community

# # SWAY
# emerge -v gui-wm/sway x11-terms/alacritty x11-terms/st

# # GAMES
# emerge -v games-util/lutris

emerge -v --changed-use net-misc/openssh
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config

systemctl enable sshd.service

systemctl enable zfs.target
systemctl enable zfs-import-cache
systemctl enable zfs-mount
systemctl enable zfs-import.target

########################## SYSTEMD + ZFS
## Create a service to import /boot automatically and enable it:
systemctl enable zfs-import-bpool.service


########################## NETWORK
## enable network service
ln -snf /run/systemd/resolve/resolv.conf /etc/resolv.conf
systemctl enable systemd-resolved.service
systemctl enable systemd-networkd.service


#mkdir /etc/portage/package.mask
#echo '>=x11-drivers/nvidia-drivers-460.67 ~amd64' > /etc/portage/package.accept_keywords/nvidia
#echo 'x11-drivers/nvidia-drivers NVIDIA-r2' >> /etc/portage/package.license

# mv /grub /etc/default/grub

mount -o remount,rw /sys/firmware/efi/efivars/

emerge @module-rebuild
genkernel initramfs --kernel-config=/usr/src/linux/.config --keymap --makeopts=-j12 --mountboot --no-clean --zfs
mkdir /boot/grub
grub-mkconfig -o /boot/grub/grub.cfg
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GentooOnZFS --recheck --no-floppy
