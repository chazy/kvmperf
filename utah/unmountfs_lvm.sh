#!/bin/bash

source fs-setup.sh

umount $MOUNTPOINT
kpartx -d /dev/$VGNAME/$NAME
