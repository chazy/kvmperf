#!/bin/bash

if [[ -f .localconf ]]; then
	source .localconf
fi

DO_POWER=0
POWER_PID=0
if [[ -f powerconf ]]; then
	source powerconf
fi

TIMELOG=time.txt
TIME="/usr/bin/time --format=%e -o $TIMELOG --append"
KERNEL="linux-3.6"
KERNEL_TAR="$KERNEL.tar.bz2"

if [[ -n "$REPTS_LIM" && $REPTS_LIM -lt $REPTS ]]; then
	REPTS="$REPTS_LIM"
fi

# Host Type Specific Defines
if [[ "$ARCH" == "x86" ]]; then
	export ARCH=arm
	export CROSS_COMPILE=arm-linux-gnueabi-
else # ARM
	export ARCH=arm
	export CROSS_COMPILE=""
fi

if [[ -f power.sh ]]; then
	source power.sh
fi
