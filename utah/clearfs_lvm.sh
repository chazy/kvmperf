#!/bin/bash

source fs-setup.sh

lvremove $VGNAME/$NAME
vgremove $VGNAME
pvremove /dev/$DISK
