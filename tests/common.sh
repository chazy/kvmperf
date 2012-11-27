#!/bin/bash

TIMELOG=time.txt
TIME="/usr/bin/time --format=%e -o $TIMELOG --append"
WEBHOST="192.168.27.90"
KERNEL="linux-3.6"
KERNEL_TAR="$KERNEL.tar.bz2"
REPTS=2

# Host Type Specific Defines
KERNEL_BUILD_CMD="make -j$REPTS zImage"
