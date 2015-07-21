#!/bin/bash

BD=/dev/vg_domU1/domU1

mkdir -p /vm
./mountfs_xen.sh

mount -t proc none /vm/proc
mount -o bind /dev /vm/dev
mount -t sysfs sys /vm/sys
echo "(hd0) $BD" > /vm/boot/grub/device.map
chroot /vm /usr/sbin/update-grub
chroot /vm /usr/sbin/grub-install --force --no-floppy '(hd0)'
rm /vm/boot/grub/device.map

umount /vm/sys
umount /vm/dev
umount /vm/proc

./unmountfs_xen.sh
