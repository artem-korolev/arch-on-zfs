#!/bin/bash


SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
ARCH_INSTALLER_REPO_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

cd /tmp
rm -Rf arch-install-iso
cp -r /usr/share/archiso/configs/releng ./arch-install-iso
cd ./arch-install-iso
cp -R ${ARCH_INSTALLER_REPO_DIR} ./airootfs/root/installer
./build.sh -v
