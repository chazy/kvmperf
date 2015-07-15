#!/bin/bash

DISK=sda2
NAME=domU1

parted /dev/sda mkpart domu 18G 58G #this will create sda2
pvcreate /dev/$DISK	#will make it lvm2
vgcreate vg_$NAME /dev/$DISK
vgs

lvcreate -n $NAME -l 100%FREE vg_$NAME
/sbin/mkfs.ext4 /dev/vg_$NAME/$NAME

mount /dev/vg_$NAME/$NAME /mnt
pushd /mnt
cp -a /srv/vm/linaro-trusty/* .
popd
umount /mnt
