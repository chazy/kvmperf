#!/bin/bash

DISK=sdb
NAME=domU1
VGNAME=vg_$NAME

kpartx -a /dev/$VGNAME/$NAME
mount /dev/mapper/vg_domU1-domU1p1 /vm
