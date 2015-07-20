#!/bin/bash

DISK=sdb
NAME=domU1
VGNAME=vg_$NAME

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

parted -s -a optimal /dev/sdb -- mklabel msdos 
pvcreate /dev/$DISK	#will make it lvm2
vgcreate $VGNAME /dev/$DISK
vgs

lvcreate -n $NAME -l 100%FREE vg_$NAME
/sbin/mkfs.ext4 /dev/$VGNAME/$NAME

mkdir -p /vm
mount /dev/$VGNAME/$NAME /vm
