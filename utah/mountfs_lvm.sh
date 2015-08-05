#!/bin/bash

source fs-setup.sh


mkdir -p $MOUNTPOINT

kpartx -a /dev/$VGNAME/$NAME
mount /dev/mapper/${VGNAME}-${NAME}p1 $MOUNTPOINT
