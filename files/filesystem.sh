#!/bin/bash

set -euo pipefail

# partitions
dd if=/dev/zero of=/dev/sda bs=1MiB count=1 status=none
xargs -L1 parted --script /dev/sda -- <<EOF
mklabel msdos
mkpart primary fat32 1MiB 512MB
mkpart primary 512MB 100%
set 1 boot on
EOF

fdisk -l /dev/sda

mkfs.fat /dev/sda1
fatlabel /dev/sda1 BOOT

echo -n $LUKS_PASSWORD | cryptsetup luksFormat /dev/sda2
echo -n $LUKS_PASSWORD | cryptsetup open /dev/sda2 sda2 -d -

pvcreate /dev/mapper/sda2
pvscan
vgcreate vgmain /dev/mapper/sda2
vgscan

lvcreate -L '2G' -n swap vgmain
lvcreate -l '100%FREE' -n root vgmain
lvscan

mkswap --label SWAP /dev/vgmain/swap
swapon /dev/vgmain/swap

mke2fs -t ext4 -L ROOT /dev/vgmain/root
mount /dev/vgmain/root /mnt

mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

