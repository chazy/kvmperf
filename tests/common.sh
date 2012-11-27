#!/bin/bash

if [[ -f .localconf ]]; then
	source .localconf
fi

TIMELOG=time.txt
TIME="/usr/bin/time --format=%e -o $TIMELOG --append"
KERNEL="linux-3.6"
KERNEL_TAR="$KERNEL.tar.bz2"
REPTS=2

# Host Type Specific Defines
if [[ "$ARCH" == "x86" ]]; then
	export ARCH=arm
	export CROSS_COMPILE=arm-linux-gnueabi-
else # ARM
	export ARCH=arm
	export CROSS_COMPILE=""
fi
