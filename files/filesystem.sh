#!/bin/bash

set -euo pipefail

# required env
# - LABEL filestystem label

# partitions
dd if=/dev/zero of=/dev/sda bs=1MiB count=1 status=none
xargs -L1 parted --script /dev/sda -- <<EOF
mklabel msdos
mkpart primary fat32 1MiB 512MB
mkpart primary linux-swap 512MB 4GB
mkpart primary ext4 4GB 100%
set 1 boot on
EOF

mkfs.fat /dev/sda1
fatlabel /dev/sda1 BOOT

# TODO: encrypted swap
mkswap --label SWAP /dev/sda2
swapon /dev/sda2

echo -n $LUKS_PASSWORD | cryptsetup luksFormat /dev/sda3
echo -n $LUKS_PASSWORD | cryptsetup open /dev/sda3 root -d -
mke2fs -t ext4 -L ROOT /dev/mapper/root
mount /dev/mapper/root /mnt

mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

