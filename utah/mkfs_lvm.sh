#!/bin/bash

DISK=sdb
NAME=guest0
VGNAME=vg_kvm

vgdisplay $VGNAME 2>&1 > /dev/null
if [[ $? == 0 ]]; then
	read -r -p "Volume group $VGNAME already exists, continue? [y/N]" response
	case $response in
		[yY][eE][sS]|[yY])
			break
			;;
		*)
			echo "Aborting"
			exit 0
			;;
	esac
fi

parted -s -a optimal /dev/$DISK -- mklabel msdos 
pvcreate /dev/$DISK	#will make it lvm2
vgcreate $VGNAME /dev/$DISK
vgs

lvcreate -n $NAME -L 30G $VGNAME
parted -s -a optimal /dev/$VGNAME/$NAME -- mklabel msdos mkpart primary ext4 1 -1

kpartx -a /dev/$VGNAME/$NAME
/sbin/mkfs.ext4 /dev/mapper/${VGNAME}-${NAME}p1
kpartx -d /dev/$VGNAME/$NAME
