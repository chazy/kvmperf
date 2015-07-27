#!/bin/bash

source fs-setup.sh

BD=/dev/$VGNAME/$NAME

./mountfs_lvm.sh

mount -t proc none $MOUNTPOINT/proc
mount -o bind /dev $MOUNTPOINT/dev
mount -t sysfs sys $MOUNTPOINT/sys
echo "(hd0) $BD" > $MOUNTPOINT/boot/grub/device.map
chroot $MOUNTPOINT /usr/sbin/update-grub
chroot $MOUNTPOINT /usr/sbin/grub-install --force --no-floppy '(hd0)'
rm $MOUNTPOINT/boot/grub/device.map

umount $MOUNTPOINT/sys
umount $MOUNTPOINT/dev
umount $MOUNTPOINT/proc

./unmountfs_lvm.sh
