#!/bin/bash

DISK=sdb
NAME=domU1
VGNAME=vg_$NAME

lvremove $VGNAME/$NAME
vgremove $VGNAME
pvremove /dev/$DISK
