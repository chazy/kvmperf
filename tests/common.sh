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

function power_start()
{
	if [[ $DO_POWER == 0 ]]; then
		return 0
	fi

	if [[ "$ARCH" == "arm" ]]; then
		remote_cmd='cd /home/christoffer/src/arm-probe && arm-probe/arm-probe -c POWER0 > /tmp/power.values 2>/dev/null'
	elif [[ "$ARCH" == "x86" ]]; then
		remote_cmd='powerstat -o /tmp/power.values -d 0 1'
	fi

	ssh root@$POWERHOST "bash -c '$remote_cmd'" &
	POWER_PID=$!
}

# Run with
# arg1: test iteration number
function power_end()
{
	test_iter="$1"
	postfix=`printf '%02d' $test_iter` #ensure ls -1 in right order

	if [[ $DO_POWER == 0 ]]; then
		return 0
	fi

	out_file="power.values.$postfix"

	if [[ "$ARCH" == "arm" ]]; then
		remote_cmd='pkill -SIGINT arm-probe'
	elif [[ "$ARCH" == "x86" ]]; then
		remote_cmd='pkill powerstat'
	fi


	if [[ $POWER_PID == 0 ]]; then
		echo "Error: Do not have PID of ssh to power measurement session!" >&2
		return 1
	fi

	ssh root@$POWERHOST "bash -c '$remote_cmd'"
	sleep 2

	kill $POWER_PID > /dev/null 2>&1
	POWER_PID=0
	scp -q root@$POWERHOST:/tmp/power.values $POWEROUT/$out_file
}
