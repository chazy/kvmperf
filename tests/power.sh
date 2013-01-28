#!/bin/bash

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
