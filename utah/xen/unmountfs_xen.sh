#!/bin/bash

DISK=sdb
NAME=domU1
VGNAME=vg_$NAME

umount /vm
kpartx -d /dev/$VGNAME/$NAME
