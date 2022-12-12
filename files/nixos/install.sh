#!/bin/bash

# required env:
# - NIX_RELEASE
# - NIX_CHANNEL
# - ROOT_SSH_KEY

set -euo pipefail

readonly NIX_INSTALL_URL="https://releases.nixos.org/nix/nix-${NIX_RELEASE}/install"
readonly NIX_CHANNEL_URL="https://channels.nixos.org/nixos-${NIX_CHANNEL}"

# XXX: get nix install working in rescue system
groupadd --force --system nixbld
useradd --system --gid nixbld --groups nixbld nixbld

# create a temporary installer dir on the target disk
mkdir -p -m 0755 /mnt/installer/nix
chown root /mnt/installer/nix
mkdir -m 0755 /nix

# link the installer dir to /nix
mount -o bind /mnt/installer/nix /nix

# obtain nix tools
curl --fail -o install     "${NIX_INSTALL_URL}"
curl --fail -o install.asc "${NIX_INSTALL_URL}.asc"
gpg --verify ./install.asc ./install
sh ./install

# make nix tools available to current shell
set +u
. /root/.nix-profile/etc/profile.d/nix.sh
set -u

# prepare nix
nix-channel --add "${NIX_CHANNEL_URL}" nixpkgs
nix-channel --update
nix-env -iE "_: with import <nixpkgs/nixos> { configuration = {}; }; with config.system.build; [ nixos-generate-config nixos-install nixos-enter manual.manpages ]"

# XXX: template the nix config previously injected by packer
for i in NIX_CHANNEL ROOT_SSH_KEY; do
  sed -i "s|{{ $i }}|${!i}|"  /mnt/etc/nixos/configuration.nix
done
nixos-generate-config --root /mnt

# actual install
nixos-install --no-root-passwd

# unlink the installer from /nix
umount /nix

# remove the installer tmp from target disk
echo "Removing installer traces"
rm -rf /mnt/installer

# echo "Running first rebuild switch"
# chroot_bash=$(find /mnt/nix -wholename "*-bash-*/bin/bash" | tail -n 1 | sed -e 's/\/mnt//')
# chroot_nix_channel=$(find /mnt/nix -wholename "*-nix-*/bin/nix-channel" | tail -n 1 | sed -e 's/\/mnt//')
# chroot_nixos_rebuild=$(find /mnt/nix -wholename "*-nixos-*/bin/nixos-rebuild" | tail -n 1 | sed -e 's/\/mnt//')
# mount -t proc /proc /mnt/proc/
# mount --rbind /sys /mnt/sys/
# mount --rbind /dev /mnt/dev/
# mkdir /mnt/tmp
# chroot /mnt ${chroot_bash} -c "${chroot_nix_channel} --update && ${chroot_nixos_rebuild} switch"
